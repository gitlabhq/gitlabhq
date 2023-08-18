import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlButtonGroup,
  GlButton,
  GlIcon,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ImportActionsCell from '~/import_entities/import_groups/components/import_actions_cell.vue';

describe('import actions cell', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(ImportActionsCell, {
      propsData: {
        isFinished: false,
        isAvailableForImport: false,
        isInvalid: false,
        ...props,
      },
      stubs: {
        GlButtonGroup,
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  };

  describe('when group is available for import', () => {
    beforeEach(() => {
      createComponent({ isAvailableForImport: true });
    });

    it('renders import dropdown', () => {
      const button = wrapper.findComponent(GlButton);
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Import with projects');
    });

    it('does not render icon with a hint', () => {
      expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
    });
  });

  describe('when group is finished', () => {
    beforeEach(() => {
      createComponent({ isAvailableForImport: false, isFinished: true });
    });

    it('renders re-import dropdown', () => {
      const button = wrapper.findComponent(GlButton);
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Re-import with projects');
    });

    it('renders icon with a hint', () => {
      const icon = wrapper.findComponent(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.attributes().title).toBe(
        'Re-import creates a new group. It does not sync with the existing group.',
      );
    });
  });

  it('does not render import dropdown when group is not available for import', () => {
    createComponent({ isAvailableForImport: false });

    const dropdown = wrapper.findComponent(GlDisclosureDropdown);
    expect(dropdown.exists()).toBe(false);
  });

  it('renders import dropdown as disabled when group is invalid', () => {
    createComponent({ isInvalid: true, isAvailableForImport: true });

    const dropdown = wrapper.findComponent(GlDisclosureDropdown);
    expect(dropdown.props().disabled).toBe(true);
  });

  it('emits import-group event when import button is clicked', () => {
    createComponent({ isAvailableForImport: true });

    const button = wrapper.findComponent(GlButton);
    button.vm.$emit('click');

    expect(wrapper.emitted('import-group')).toHaveLength(1);
  });

  describe.each`
    isFinished | expectedAction
    ${false}   | ${'Import'}
    ${true}    | ${'Re-import'}
  `(
    'group is available for import and finish status is $isFinished',
    ({ isFinished, expectedAction }) => {
      beforeEach(() => {
        createComponent({ isAvailableForImport: true, isFinished });
      });

      it('render import dropdown', () => {
        const button = wrapper.findComponent(GlButton);
        const dropdown = wrapper.findComponent(GlDisclosureDropdown);
        expect(button.element).toHaveText(`${expectedAction} with projects`);
        expect(dropdown.findComponent(GlDisclosureDropdownItem).text()).toBe(
          `${expectedAction} without projects`,
        );
      });

      it('request migrate projects by default', () => {
        const button = wrapper.findComponent(GlButton);
        button.vm.$emit('click');

        expect(wrapper.emitted('import-group')[0]).toStrictEqual([{ migrateProjects: true }]);
      });

      it('request not to migrate projects via dropdown option', () => {
        const dropdown = wrapper.findComponent(GlDisclosureDropdown);
        dropdown.findComponent(GlDisclosureDropdownItem).vm.$emit('action');

        expect(wrapper.emitted('import-group')[0]).toStrictEqual([{ migrateProjects: false }]);
      });
    },
  );
});
