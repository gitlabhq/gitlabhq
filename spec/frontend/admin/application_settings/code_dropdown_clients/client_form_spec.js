import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ClientForm from '~/admin/application_settings/code_dropdown_clients/client_form.vue';

describe('CodeDropdownClientForm', () => {
  let wrapper;

  const vscodium = {
    name: 'VSCodium',
    ssh_url_template: 'vscodium://vscode.git/clone?url={url}',
    http_url_template: 'vscodium://vscode.git/clone?url={url}',
  };

  const createComponent = ({ client = null, otherClients = [] } = {}) => {
    wrapper = mountExtended(ClientForm, { propsData: { client, otherClients } });
  };

  const findNameInput = () => wrapper.findByTestId('client-name-input');
  const findSshInput = () => wrapper.findByTestId('client-ssh-template-input');
  const findHttpInput = () => wrapper.findByTestId('client-http-template-input');
  const findSubmit = () => wrapper.findByTestId('submit-client-button');

  const fillIn = async ({ name = '', ssh = '', http = '' } = {}) => {
    await findNameInput().setValue(name);
    await findSshInput().setValue(ssh);
    await findHttpInput().setValue(http);
  };

  const submit = async () => {
    await wrapper.find('form').trigger('submit');
    await nextTick();
  };

  const submitEvents = () => wrapper.emitted('submit');

  // The invalid-feedback text is always in the DOM and is only revealed by the
  // `!gl-block` class once the field is in the invalid state, so asserting on the
  // text alone would pass even while it is hidden.
  const visibleErrors = () =>
    wrapper
      .findAll('.invalid-feedback')
      .wrappers.filter((feedback) => feedback.classes().includes('!gl-block'))
      .map((feedback) => feedback.text());

  const invalidFields = () =>
    [findNameInput(), findSshInput(), findHttpInput()].filter((input) =>
      input.classes().includes('is-invalid'),
    );

  describe('a valid entry', () => {
    it('emits submit with trimmed values', async () => {
      createComponent();
      await fillIn({ name: '  VSCodium  ', ssh: `  ${vscodium.ssh_url_template}  ` });
      await submit();

      expect(submitEvents()).toEqual([
        [{ name: 'VSCodium', ssh_url_template: vscodium.ssh_url_template, http_url_template: '' }],
      ]);
    });
  });

  describe('before the first submit', () => {
    it('shows no errors while the form is being filled in', async () => {
      createComponent();
      await fillIn({ name: '' });

      expect(visibleErrors()).toEqual([]);
      expect(invalidFields()).toHaveLength(0);
    });
  });

  // The XSS payloads below are test data for the scheme check, not live URLs.
  /* eslint-disable no-script-url */
  describe.each`
    scenario                    | fields                                                     | message
    ${'a blank name'}           | ${{ name: '', ssh: 'vscode://clone?url={url}' }}           | ${'Enter a display name.'}
    ${'no template at all'}     | ${{ name: 'VSCodium' }}                                    | ${'Enter at least one URL template.'}
    ${'a missing placeholder'}  | ${{ name: 'VSCodium', ssh: 'vscode://clone' }}             | ${'URL template must contain {url} exactly once.'}
    ${'a repeated placeholder'} | ${{ name: 'VSCodium', ssh: 'vscode://{url}/{url}' }}       | ${'URL template must contain {url} exactly once.'}
    ${'no scheme'}              | ${{ name: 'VSCodium', ssh: 'vscode.git/clone?url={url}' }} | ${'URL template must be a valid URL with a scheme, for example vscode://.'}
    ${'a javascript: scheme'}   | ${{ name: 'VSCodium', ssh: 'javascript:alert({url})' }}    | ${'The javascript scheme is not allowed.'}
    ${'a mixed-case bypass'}    | ${{ name: 'VSCodium', ssh: 'JaVaScRiPt:alert({url})' }}    | ${'The JaVaScRiPt scheme is not allowed.'}
    ${'a data: scheme'}         | ${{ name: 'VSCodium', ssh: 'data:text/html,{url}' }}       | ${'The data scheme is not allowed.'}
    ${'a file: scheme'}         | ${{ name: 'VSCodium', ssh: 'file:///etc/{url}' }}          | ${'The file scheme is not allowed.'}
  `('$scenario', ({ fields, message }) => {
    beforeEach(async () => {
      createComponent();
      await fillIn(fields);
      await submit();
    });

    it('blocks submit', () => {
      expect(submitEvents()).toBeUndefined();
    });

    it('shows the error inline and marks the field invalid', () => {
      expect(visibleErrors()).toContain(message);
      expect(invalidFields().length).toBeGreaterThan(0);
    });
  });
  /* eslint-enable no-script-url */

  describe('duplicates against other entries', () => {
    it('rejects a name already used by another client', async () => {
      createComponent({ otherClients: [vscodium] });
      await fillIn({ name: 'vscodium', ssh: 'fork://clone?url={url}' });
      await submit();

      expect(submitEvents()).toBeUndefined();
      expect(visibleErrors()).toContain('Another client already uses this display name.');
    });

    it('rejects a template already used by another client', async () => {
      createComponent({ otherClients: [vscodium] });
      await fillIn({ name: 'Fork', ssh: vscodium.ssh_url_template });
      await submit();

      expect(submitEvents()).toBeUndefined();
      expect(visibleErrors()).toContain('Another client already uses this URL template.');
    });

    it('allows one entry to reuse its own template for SSH and HTTPS', async () => {
      createComponent();
      await fillIn({
        name: 'VSCodium',
        ssh: vscodium.ssh_url_template,
        http: vscodium.ssh_url_template,
      });
      await submit();

      expect(submitEvents()).toHaveLength(1);
    });
  });

  describe('editing an existing client', () => {
    it('does not flag the edited entry as a duplicate of itself', async () => {
      createComponent({ client: vscodium, otherClients: [] });
      await submit();

      expect(submitEvents()).toHaveLength(1);
    });

    it('labels the submit button "Save"', () => {
      createComponent({ client: vscodium });

      expect(findSubmit().text()).toBe('Save');
    });
  });
});
