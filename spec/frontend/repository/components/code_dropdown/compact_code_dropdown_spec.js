import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CompactCodeDropdown from '~/repository/components/code_dropdown/compact_code_dropdown.vue';
import CodeDropdownItem from '~/vue_shared/components/code_dropdown/code_dropdown_item.vue';

describe('Compact Code Dropdown coomponent', () => {
  let wrapper;
  const sshUrl = 'ssh://foo.bar';
  const httpUrl = 'http://foo.bar';
  const httpsUrl = 'https://foo.bar';
  const defaultPropsData = {
    sshUrl,
    httpUrl,
  };

  const findCodeDropdownItems = () => wrapper.findAllComponents(CodeDropdownItem);
  const findCodeDropdownItemAtIndex = (index) => findCodeDropdownItems().at(index);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(CompactCodeDropdown, {
      propsData,
    });
  };

  describe('copyGroup', () => {
    describe('rendering', () => {
      it.each`
        name      | index | link
        ${'SSH'}  | ${0}  | ${sshUrl}
        ${'HTTP'} | ${1}  | ${httpUrl}
      `('renders correct link and a copy-button for $name', ({ index, link }) => {
        createComponent();

        const item = findCodeDropdownItemAtIndex(index);
        expect(item.props('link')).toBe(link);
      });

      it.each`
        name         | value
        ${'sshUrl'}  | ${sshUrl}
        ${'httpUrl'} | ${httpUrl}
      `('does not fail if only $name is set', ({ name, value }) => {
        createComponent({ [name]: value });

        expect(findCodeDropdownItemAtIndex(0).props('link')).toBe(value);
      });
    });

    describe('functionality', () => {
      it.each`
        name         | value
        ${'sshUrl'}  | ${null}
        ${'httpUrl'} | ${null}
      `('allows null values for the props', ({ name, value }) => {
        createComponent({ ...defaultPropsData, [name]: value });

        expect(findCodeDropdownItems().length).toBe(1);
      });

      it('correctly calculates httpLabel for HTTPS protocol', () => {
        createComponent({ httpUrl: httpsUrl });

        expect(findCodeDropdownItemAtIndex(0).attributes('label')).toContain('HTTPS');
      });

      it.each`
        name      | index | link
        ${'SSH'}  | ${0}  | ${sshUrl}
        ${'HTTP'} | ${1}  | ${httpUrl}
      `('does not close dropdown on $name item click', () => {
        createComponent();
        expect(findDropdown().props('autoClose')).toBe(false);
      });
    });
  });
});
