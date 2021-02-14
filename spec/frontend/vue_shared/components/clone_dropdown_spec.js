import { GlFormInputGroup, GlDropdownSectionHeader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CloneDropdown from '~/vue_shared/components/clone_dropdown.vue';

describe('Clone Dropdown Button', () => {
  let wrapper;
  const sshLink = 'ssh://foo.bar';
  const httpLink = 'http://foo.bar';
  const httpsLink = 'https://foo.bar';
  const defaultPropsData = {
    sshLink,
    httpLink,
  };

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMount(CloneDropdown, {
      propsData,
      stubs: {
        'gl-form-input-group': GlFormInputGroup,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      createComponent();
      expect(wrapper.element).toMatchSnapshot();
    });

    it.each`
      name      | index | value
      ${'SSH'}  | ${0}  | ${sshLink}
      ${'HTTP'} | ${1}  | ${httpLink}
    `('renders correct link and a copy-button for $name', ({ index, value }) => {
      createComponent();
      const group = wrapper.findAll(GlFormInputGroup).at(index);
      expect(group.props('value')).toBe(value);
      expect(group.find(GlFormInputGroup).exists()).toBe(true);
    });

    it.each`
      name          | value
      ${'sshLink'}  | ${sshLink}
      ${'httpLink'} | ${httpLink}
    `('does not fail if only $name is set', ({ name, value }) => {
      createComponent({ [name]: value });

      expect(wrapper.find(GlFormInputGroup).props('value')).toBe(value);
      expect(wrapper.findAll(GlDropdownSectionHeader).length).toBe(1);
    });
  });

  describe('functionality', () => {
    it.each`
      name          | value
      ${'sshLink'}  | ${null}
      ${'httpLink'} | ${null}
    `('allows null values for the props', ({ name, value }) => {
      createComponent({ ...defaultPropsData, [name]: value });

      expect(wrapper.findAll(GlDropdownSectionHeader).length).toBe(1);
    });

    it('correctly calculates httpLabel for HTTPS protocol', () => {
      createComponent({ httpLink: httpsLink });
      expect(wrapper.find(GlDropdownSectionHeader).text()).toContain('HTTPS');
    });
  });
});
