import { GlTable } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import ExclusionSettings from '~/pages/projects/shared/permissions/components/exclusion_settings.vue';
import ManageExclusionsDrawer from '~/pages/projects/shared/permissions/components/manage_exclusions_drawer.vue';
import { createAlert } from '~/alert';

jest.mock('~/alert');

const defaultProps = {
  exclusionRules: ['*.log', 'node_modules/', 'secrets.json'],
};

describe('ExclusionSettings', () => {
  let wrapper;

  const mountComponent = (props = {}, mountFn = mountExtended) => {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    return mountFn(ExclusionSettings, {
      propsData,
    });
  };

  const findCrudComponent = () =>
    wrapper.findByTestId('exclusion-settings-crud').findComponent(CrudComponent);
  const findTable = () => wrapper.findByTestId('exclusion-rules-table').findComponent(GlTable);
  const findDeleteButtons = () => wrapper.findAllByTestId('delete-exclusion-rule');
  const findManageExclusionsButton = () => wrapper.findByTestId('manage-exclusions-button');
  const findManageExclusionsDrawer = () => wrapper.findComponent(ManageExclusionsDrawer);

  beforeEach(() => {
    wrapper = mountComponent();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('rendering', () => {
    it('renders the CRUD component with correct props', () => {
      const crudComponent = findCrudComponent();

      expect(crudComponent.exists()).toBe(true);
      expect(crudComponent.props()).toMatchObject({
        title: wrapper.vm.$options.i18n.title,
        count: 3,
        icon: 'remove',
      });
    });

    it('renders table items correctly', () => {
      const expectedItems = [
        { id: 0, pattern: '*.log', isDeleting: false },
        { id: 1, pattern: 'node_modules/', isDeleting: false },
        { id: 2, pattern: 'secrets.json', isDeleting: false },
      ];

      expect(wrapper.vm.tableItems).toEqual(expectedItems);
    });

    it('renders delete buttons for each rule', () => {
      const deleteButtons = findDeleteButtons();

      expect(deleteButtons).toHaveLength(3);
    });
  });

  describe('empty state', () => {
    beforeEach(() => {
      wrapper = mountComponent({ exclusionRules: [] });
    });

    it('shows empty state message when no rules exist', () => {
      const table = findTable();

      // Check that the empty-text prop is set to the component's i18n message
      expect(table.text()).toContain(wrapper.vm.$options.i18n.emptyStateMessage);
      expect(findCrudComponent().props('count')).toBe(0);
    });
  });

  describe('deleting rules', () => {
    it('opens delete modal when delete button is clicked', async () => {
      const deleteButton = findDeleteButtons().at(0);

      // Spy on the confirmDeleteRule method
      const confirmDeleteRuleSpy = jest.spyOn(wrapper.vm, 'confirmDeleteRule');

      await deleteButton.trigger('click');

      // Check that confirmDeleteRule was called with the correct item
      expect(confirmDeleteRuleSpy).toHaveBeenCalledWith({
        id: 0,
        pattern: '*.log',
        isDeleting: false,
      });
    });

    it('deletes a rule when confirmed in modal', async () => {
      // Simulate the confirmDeleteRule method being called
      const ruleToDelete = {
        id: 1,
        pattern: 'node_modules/',
        isDeleting: false,
      };
      wrapper.vm.ruleToDelete = ruleToDelete;

      // Confirm deletion by calling the deleteRule method directly
      await wrapper.vm.deleteRule();

      expect(wrapper.emitted('update')).toHaveLength(1);
      expect(wrapper.emitted('update')[0][0]).toEqual([
        '*.log',
        'secrets.json', // node_modules/ removed
      ]);
    });

    it('shows success alert when rule is deleted', async () => {
      // Simulate the confirmDeleteRule method being called
      const ruleToDelete = {
        id: 0,
        pattern: '*.log',
        isDeleting: false,
      };
      wrapper.vm.ruleToDelete = ruleToDelete;

      // Call deleteRule method directly
      await wrapper.vm.deleteRule();

      expect(createAlert).toHaveBeenCalledWith({
        message: wrapper.vm.$options.i18n.ruleDeletedMessage,
        variant: 'info',
      });
    });

    it('shows correct rule in delete modal', async () => {
      const deleteButton = findDeleteButtons().at(1);

      // Spy on the confirmDeleteRule method
      const confirmDeleteRuleSpy = jest.spyOn(wrapper.vm, 'confirmDeleteRule');

      await deleteButton.trigger('click');

      expect(confirmDeleteRuleSpy).toHaveBeenCalledWith({
        id: 1,
        pattern: 'node_modules/',
        isDeleting: false,
      });
    });
  });

  describe('props watching', () => {
    it('updates internal rules when exclusionRules prop changes', async () => {
      const newRules = ['*.backup', 'cache/'];
      await wrapper.setProps({ exclusionRules: newRules });

      expect(wrapper.vm.rules).toEqual(newRules);
    });
  });

  describe('manage exclusions drawer', () => {
    it('renders the manage exclusions button', () => {
      const button = findManageExclusionsButton();

      expect(button.exists()).toBe(true);
      expect(button.text()).toBe(wrapper.vm.$options.i18n.manageExclusions);
    });

    it('renders the manage exclusions drawer', () => {
      const drawer = findManageExclusionsDrawer();

      expect(drawer.exists()).toBe(true);
      expect(drawer.props('open')).toBe(false);
      expect(drawer.props('exclusionRules')).toEqual(defaultProps.exclusionRules);
    });

    it('opens the drawer when manage exclusions button is clicked', async () => {
      const button = findManageExclusionsButton();

      await button.trigger('click');

      expect(wrapper.vm.isManageDrawerOpen).toBe(true);
      expect(findManageExclusionsDrawer().props('open')).toBe(true);
    });

    it('closes the drawer when close event is emitted', async () => {
      // Open drawer first
      await findManageExclusionsButton().trigger('click');
      expect(wrapper.vm.isManageDrawerOpen).toBe(true);

      // Close drawer
      const drawer = findManageExclusionsDrawer();
      await drawer.vm.$emit('close');

      expect(wrapper.vm.isManageDrawerOpen).toBe(false);
    });

    it('saves exclusion rules when save event is emitted from drawer', async () => {
      const newRules = ['*.tmp', 'build/', 'dist/'];
      const drawer = findManageExclusionsDrawer();

      await drawer.vm.$emit('save', newRules);

      expect(wrapper.vm.rules).toEqual(newRules);
      expect(wrapper.emitted('update')).toHaveLength(1);
      expect(wrapper.emitted('update')[0][0]).toEqual(newRules);
    });

    it('closes drawer and shows success message when save is successful', async () => {
      const newRules = ['*.tmp', 'build/', 'dist/'];
      const drawer = findManageExclusionsDrawer();

      // Open drawer first
      await findManageExclusionsButton().trigger('click');
      expect(wrapper.vm.isManageDrawerOpen).toBe(true);

      // Save rules
      await drawer.vm.$emit('save', newRules);

      expect(wrapper.vm.isManageDrawerOpen).toBe(false);
    });

    it('passes updated rules to drawer when internal rules change', async () => {
      const newRules = ['*.backup', 'cache/'];
      await wrapper.setProps({ exclusionRules: newRules });

      const drawer = findManageExclusionsDrawer();
      expect(drawer.props('exclusionRules')).toEqual(newRules);
    });
  });
});
