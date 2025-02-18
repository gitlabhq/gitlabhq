import { shallowMount } from '@vue/test-utils';
import {
  GlButton,
  GlButtonGroup,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import WorkItemCreateBranchMergeRequestSplitButton from '~/work_items/components/work_item_development/work_item_create_branch_merge_request_split_button.vue';
import WorkItemCreateBranchMergeRequestModal from '~/work_items/components/work_item_development/work_item_create_branch_merge_request_modal.vue';

describe('WorkItemCreateBranchMergeRequestSplitButton', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMount(WorkItemCreateBranchMergeRequestSplitButton, {
      propsData: {
        workItemFullPath: 'group/project',
        workItemType: 'issue',
        workItemId: '1',
        workItemIid: '100',
        projectId: 'gid://gitlab/Project/7',
        isConfidentialWorkItem: false,
        ...props,
      },
    });
  };

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findMainButton = () => findButtonGroup().findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownGroups = () => findDropdown().findAllComponents(GlDisclosureDropdownGroup);
  const findCreateModal = () => wrapper.findComponent(WorkItemCreateBranchMergeRequestModal);

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('component rendering', () => {
    it('renders the component correctly', () => {
      expect(findButtonGroup().exists()).toBe(true);
      expect(findDropdown().exists()).toBe(true);
    });

    it('shows loading indicator till the permission call is made', () => {
      expect(findMainButton().text()).toBe('Create merge request');
      expect(findMainButton().props('loading')).toBe(true);
    });

    it('renders the main merge request button with correct text', async () => {
      await findCreateModal().vm.$emit('fetchedPermissions', true);

      expect(findMainButton().text()).toBe('Create merge request');
      expect(findMainButton().attributes('icon')).toBe('merge-request');
    });

    it('renders the main buttion with correct text when a confidential work item', async () => {
      wrapper = createComponent({ isConfidentialWorkItem: true });
      await findCreateModal().vm.$emit('fetchedPermissions', true);

      expect(findMainButton().text()).toBe('Create merge request');
    });

    it('hides the button when the user does not have permission to create merge requests', async () => {
      await findCreateModal().vm.$emit('fetchedPermissions', false);

      expect(findButtonGroup().exists()).toBe(false);
    });
  });

  describe('Split button options', () => {
    it('returns correct mergeRequestGroup structure', () => {
      const groups = findDropdownGroups();
      const mergeRequestGroup = groups.at(0);
      const branchGroup = groups.at(1);

      expect(groups).toHaveLength(2);

      expect(mergeRequestGroup.props('group').name).toBe('Merge request');
      expect(mergeRequestGroup.props('group').items).toEqual([
        expect.objectContaining({
          text: 'Create merge request',
          extraAttrs: { 'data-testid': 'create-mr-dropdown-button' },
        }),
      ]);

      expect(branchGroup.props('group').name).toBe('Branch');
      expect(branchGroup.props('group').items).toEqual([
        expect.objectContaining({
          text: 'Create branch',
          extraAttrs: { 'data-testid': 'create-branch-dropdown-button' },
        }),
      ]);
    });
  });
});
