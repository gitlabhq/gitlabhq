import { GlFormInputGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import CloneCodeDropdown from '~/vue_shared/components/code_dropdown/clone_code_dropdown.vue';
import CodeDropdownCloneItem from '~/repository/components/code_dropdown/code_dropdown_clone_item.vue';

describe('CloneCodeDropdown', () => {
  let wrapper;
  const sshUrl = 'ssh://foo.bar';
  const httpUrl = 'http://foo.bar';
  const httpsUrl = 'https://foo.bar';
  const embedUrl = 'http://link.to.snippet';
  const embedCode = `<script src="${embedUrl}.js"></script>`;
  const defaultPropsData = {
    sshUrl,
    httpUrl,
    url: embedUrl,
    embeddable: true,
  };

  const findCodeDropdownCloneItems = () => wrapper.findAllComponents(CodeDropdownCloneItem);
  const findCodeDropdownCloneItemAtIndex = (index) => findCodeDropdownCloneItems().at(index);
  const findCopySshUrlButton = () => wrapper.findComponentByTestId('copy-ssh-url');
  const findCopyHttpUrlButton = () => wrapper.findComponentByTestId('copy-http-url');
  const findCopyEmbeddedCodeButton = () => wrapper.findComponentByTestId('copy-embedded-code');
  const findCopyShareUrlButton = () => wrapper.findComponentByTestId('copy-share-url');
  const findCopyKRB5UrlButton = () => wrapper.findComponentByTestId('copy-kerberos-url');

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMountExtended(CloneCodeDropdown, {
      propsData,
      stubs: {
        GlFormInputGroup,
        CloneCodeDropdown: stubComponent(CloneCodeDropdown),
      },
    });
  };

  describe('rendering', () => {
    it.each`
      name       | index | link
      ${'SSH'}   | ${0}  | ${sshUrl}
      ${'HTTP'}  | ${1}  | ${httpUrl}
      ${'Embed'} | ${2}  | ${embedCode}
      ${'Share'} | ${3}  | ${embedUrl}
    `('renders correct link and a copy-button for $name', ({ index, link }) => {
      createComponent();

      const group = findCodeDropdownCloneItemAtIndex(index);
      expect(group.props('link')).toBe(link);
    });

    it.each`
      name         | finder                   | value
      ${'sshUrl'}  | ${findCopySshUrlButton}  | ${sshUrl}
      ${'httpUrl'} | ${findCopyHttpUrlButton} | ${httpUrl}
    `('does not fail if only $name is set', ({ name, finder, value }) => {
      createComponent({ [name]: value, url: embedCode });

      expect(finder().props('link')).toBe(value);
    });

    it('only renders clone URLs if embeddable prop is false', () => {
      createComponent({ ...defaultPropsData, embeddable: false });

      expect(findCopySshUrlButton().exists()).toBe(true);
      expect(findCopyHttpUrlButton().exists()).toBe(true);
      expect(findCopyEmbeddedCodeButton().exists()).toBe(false);
      expect(findCopyShareUrlButton().exists()).toBe(false);
    });

    it('does not render Embed and Share items, if url is not provided', () => {
      createComponent({ ...defaultPropsData, url: '' });

      expect(findCopyEmbeddedCodeButton().exists()).toBe(false);
      expect(findCopyShareUrlButton().exists()).toBe(false);
    });

    it('does not render KRB5 link, if kerberosUrl is not provided', () => {
      createComponent();

      expect(findCopyKRB5UrlButton().exists()).toBe(false);
    });

    it('renders KRB5 link, if kerberosUrl is provided', () => {
      createComponent({ ...defaultPropsData, kerberosUrl: 'http://:@gitlab.com/project-2.git' });

      expect(findCopyKRB5UrlButton().exists()).toBe(true);
    });
  });

  describe('functionality', () => {
    it('correctly calculates httpLabel for HTTPS protocol', () => {
      createComponent({ ...defaultPropsData, httpUrl: httpsUrl });

      expect(findCopyHttpUrlButton().props('label')).toContain('HTTPS');
    });
  });
});
