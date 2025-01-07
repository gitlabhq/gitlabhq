import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ImportActionsCell from '~/import_entities/import_groups/components/import_actions_cell.vue';

describe('import actions cell', () => {
  let wrapper;

  const defaultProps = {
    isFinished: false,
    isAvailableForImport: false,
    isInvalid: false,
    isProjectCreationAllowed: true,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(ImportActionsCell, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItem = () => findDropdown().findComponent(GlDisclosureDropdownItem);
  const findReimportInfoIcon = () => wrapper.findByTestId('reimport-info-icon');
  const findProjectCreationWarningIcon = () =>
    wrapper.findByTestId('project-creation-warning-icon');

  describe.each`
    isProjectCreationAllowed | isAvailableForImport | isFinished | expectedButton                  | expectedDropdown                | expectedWarningIcon
    ${true}                  | ${false}             | ${false}   | ${false}                        | ${false}                        | ${false}
    ${true}                  | ${false}             | ${true}    | ${'Re-import with projects'}    | ${'Re-import without projects'} | ${false}
    ${true}                  | ${true}              | ${false}   | ${'Import with projects'}       | ${'Import without projects'}    | ${false}
    ${true}                  | ${true}              | ${true}    | ${'Re-import with projects'}    | ${'Re-import without projects'} | ${false}
    ${false}                 | ${false}             | ${false}   | ${false}                        | ${false}                        | ${false}
    ${false}                 | ${false}             | ${true}    | ${'Re-import without projects'} | ${false}                        | ${true}
    ${false}                 | ${true}              | ${false}   | ${'Import without projects'}    | ${false}                        | ${true}
    ${false}                 | ${true}              | ${true}    | ${'Re-import without projects'} | ${false}                        | ${true}
  `(
    'isProjectCreationAllowed = $isProjectCreationAllowed, isAvailableForImport = $isAvailableForImport, isFinished = $isFinished',
    ({
      isAvailableForImport,
      isFinished,
      isProjectCreationAllowed,
      expectedButton,
      expectedDropdown,
      expectedWarningIcon,
    }) => {
      beforeEach(() => {
        createComponent({ isAvailableForImport, isFinished, isProjectCreationAllowed });
      });

      if (expectedButton) {
        it(`renders button with "${expectedButton}" text`, () => {
          const button = findButton();
          expect(button.exists()).toBe(true);
          expect(button.text()).toBe(expectedButton);
        });
      } else {
        it('does not render button', () => {
          expect(findButton().exists()).toBe(false);
        });
      }

      if (expectedDropdown) {
        it(`renders dropdown with "${expectedDropdown}" text`, () => {
          expect(findDropdown().exists()).toBe(true);
          expect(findDropdownItem().text()).toBe(expectedDropdown);
        });
      } else {
        it('does not render dropdown', () => {
          expect(findDropdown().exists()).toBe(false);
        });
      }

      if (isFinished) {
        it('renders re-import info icon', () => {
          expect(findReimportInfoIcon().exists()).toBe(true);
        });
      } else {
        it('does not render re-import info icon', () => {
          expect(findReimportInfoIcon().exists()).toBe(false);
        });
      }

      if (expectedWarningIcon) {
        it('renders project creation warning icon', () => {
          expect(findProjectCreationWarningIcon().exists()).toBe(true);
        });
      } else {
        it('does not render project creation warning icon', () => {
          expect(findProjectCreationWarningIcon().exists()).toBe(false);
        });
      }
    },
  );

  it('renders import dropdown as disabled when group is invalid', () => {
    createComponent({ isInvalid: true, isAvailableForImport: true });

    expect(findDropdown().props().disabled).toBe(true);
  });

  it('emits import-group event (with projects) when import button is clicked', () => {
    createComponent({ isAvailableForImport: true });

    findButton().vm.$emit('click');

    expect(wrapper.emitted('import-group')).toHaveLength(1);
    expect(wrapper.emitted('import-group')[0]).toStrictEqual([{ migrateProjects: true }]);
  });

  it('emits import-group event (without projects) when dropdown option is clicked', () => {
    createComponent({ isAvailableForImport: true });

    findDropdownItem().vm.$emit('action');

    expect(wrapper.emitted('import-group')).toHaveLength(1);
    expect(wrapper.emitted('import-group')[0]).toStrictEqual([{ migrateProjects: false }]);
  });

  it('emits import-group event (without projects) when isProjectCreationAllowed is false and import button is clicked', () => {
    createComponent({
      isProjectCreationAllowed: false,
      isAvailableForImport: true,
    });

    findButton().vm.$emit('click');

    expect(wrapper.emitted('import-group')).toHaveLength(1);
    expect(wrapper.emitted('import-group')[0]).toStrictEqual([{ migrateProjects: false }]);
  });
});
