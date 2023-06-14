import { GlFormInputGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CloneDropdown from '~/vue_shared/components/clone_dropdown/clone_dropdown.vue';
import CloneDropdownItem from '~/vue_shared/components/clone_dropdown/clone_dropdown_item.vue';

describe('Clone Dropdown Button', () => {
  let wrapper;
  const sshLink = 'ssh://foo.bar';
  const httpLink = 'http://foo.bar';
  const httpsLink = 'https://foo.bar';
  const defaultPropsData = {
    sshLink,
    httpLink,
  };

  const findCloneDropdownItems = () => wrapper.findAllComponents(CloneDropdownItem);
  const findCloneDropdownItemAtIndex = (index) => findCloneDropdownItems().at(index);

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(CloneDropdown, {
      propsData,
      stubs: {
        GlFormInputGroup,
      },
    });
  };

  describe('rendering', () => {
    it.each`
      name      | index | link
      ${'SSH'}  | ${0}  | ${sshLink}
      ${'HTTP'} | ${1}  | ${httpLink}
    `('renders correct link and a copy-button for $name', ({ index, link }) => {
      createComponent();

      const group = findCloneDropdownItemAtIndex(index);
      expect(group.props('link')).toBe(link);
    });

    it.each`
      name          | value
      ${'sshLink'}  | ${sshLink}
      ${'httpLink'} | ${httpLink}
    `('does not fail if only $name is set', ({ name, value }) => {
      createComponent({ [name]: value });

      expect(findCloneDropdownItemAtIndex(0).props('link')).toBe(value);
    });
  });

  describe('functionality', () => {
    it.each`
      name          | value
      ${'sshLink'}  | ${null}
      ${'httpLink'} | ${null}
    `('allows null values for the props', ({ name, value }) => {
      createComponent({ ...defaultPropsData, [name]: value });

      expect(findCloneDropdownItems().length).toBe(1);
    });

    it('correctly calculates httpLabel for HTTPS protocol', () => {
      createComponent({ httpLink: httpsLink });

      expect(findCloneDropdownItemAtIndex(0).attributes('label')).toContain('HTTPS');
    });
  });
});
