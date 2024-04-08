import { GlFormInputGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import SnippetCodeDropdown from '~/vue_shared/components/code_dropdown/snippet_code_dropdown.vue';
import CodeDropdownItem from '~/vue_shared/components/code_dropdown/code_dropdown_item.vue';

describe('SnippetCodeDropdown', () => {
  let wrapper;
  const sshLink = 'ssh://foo.bar';
  const httpLink = 'http://foo.bar';
  const httpsLink = 'https://foo.bar';
  const embedUrl = 'http://link.to.snippet';
  const embedCode = `<script src="${embedUrl}.js"></script>`;
  const defaultPropsData = {
    sshLink,
    httpLink,
    url: embedUrl,
    embeddable: true,
  };

  const findCodeDropdownItems = () => wrapper.findAllComponents(CodeDropdownItem);
  const findCodeDropdownItemAtIndex = (index) => findCodeDropdownItems().at(index);
  const findCopySshUrlButton = () => wrapper.findComponentByTestId('copy-ssh-url');
  const findCopyHttpUrlButton = () => wrapper.findComponentByTestId('copy-http-url');
  const findCopyEmbeddedCodeButton = () => wrapper.findComponentByTestId('copy-embedded-code');
  const findCopyShareUrlButton = () => wrapper.findComponentByTestId('copy-share-url');

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMountExtended(SnippetCodeDropdown, {
      propsData,
      stubs: {
        GlFormInputGroup,
        SnippetCodeDropdown: stubComponent(SnippetCodeDropdown),
      },
    });
  };

  describe('rendering', () => {
    it.each`
      name       | index | link
      ${'SSH'}   | ${0}  | ${sshLink}
      ${'HTTP'}  | ${1}  | ${httpLink}
      ${'Embed'} | ${2}  | ${embedCode}
      ${'Share'} | ${3}  | ${embedUrl}
    `('renders correct link and a copy-button for $name', ({ index, link }) => {
      createComponent();

      const group = findCodeDropdownItemAtIndex(index);
      expect(group.props('link')).toBe(link);
    });

    it.each`
      name          | finder                   | value
      ${'sshLink'}  | ${findCopySshUrlButton}  | ${sshLink}
      ${'httpLink'} | ${findCopyHttpUrlButton} | ${httpLink}
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
  });

  describe('functionality', () => {
    it('correctly calculates httpLabel for HTTPS protocol', () => {
      createComponent({ ...defaultPropsData, httpLink: httpsLink });

      expect(findCopyHttpUrlButton().props('label')).toContain('HTTPS');
    });
  });
});
