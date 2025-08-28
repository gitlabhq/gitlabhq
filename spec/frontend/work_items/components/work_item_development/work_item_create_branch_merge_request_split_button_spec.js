import {
  GlButton,
  GlButtonGroup,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemCreateBranchMergeRequestModal from '~/work_items/components/work_item_development/work_item_create_branch_merge_request_modal.vue';
import WorkItemCreateBranchMergeRequestSplitButton from '~/work_items/components/work_item_development/work_item_create_branch_merge_request_split_button.vue';
import namespaceMergeRequestsEnabledQuery from '~/work_items/graphql/namespace_merge_requests_enabled.query.graphql';

Vue.use(VueApollo);

describe('WorkItemCreateBranchMergeRequestSplitButton', () => {
  let wrapper;

  const defaultNamespaceMergeRequestsEnabledHandler = jest.fn().mockResolvedValue({
    data: { workspace: { id: 'gid://gitlab/Group/33', mergeRequestsEnabled: true } },
  });

  const createComponent = ({
    props = {},
    namespaceMergeRequestsEnabledHandler = defaultNamespaceMergeRequestsEnabledHandler,
  } = {}) => {
    return shallowMount(WorkItemCreateBranchMergeRequestSplitButton, {
      apolloProvider: createMockApollo([
        [namespaceMergeRequestsEnabledQuery, namespaceMergeRequestsEnabledHandler],
      ]),
      propsData: {
        workItemFullPath: 'group/project',
        workItemType: 'issue',
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

  describe('component rendering', () => {
    it('renders the component correctly', () => {
      wrapper = createComponent();

      expect(findButtonGroup().exists()).toBe(true);
      expect(findDropdown().exists()).toBe(true);
    });

    it('shows loading indicator till the permission call is made', () => {
      wrapper = createComponent();

      expect(findMainButton().text()).toBe('Create branch');
      expect(findMainButton().props('loading')).toBe(true);
    });

    it('renders the main merge request button with correct text', async () => {
      wrapper = createComponent();
      findCreateModal().vm.$emit('fetchedPermissions', true);
      await waitForPromises();

      expect(findMainButton().text()).toBe('Create merge request');
      expect(findMainButton().attributes('icon')).toBe('merge-request');
    });

    it('renders the main button with correct text when a confidential work item', async () => {
      wrapper = createComponent({ props: { isConfidentialWorkItem: true } });
      findCreateModal().vm.$emit('fetchedPermissions', true);
      await waitForPromises();

      expect(findMainButton().text()).toBe('Create merge request');
    });

    it('hides the button when the user does not have permission to create merge requests', async () => {
      wrapper = createComponent();
      await findCreateModal().vm.$emit('fetchedPermissions', false);

      expect(findButtonGroup().exists()).toBe(false);
    });
  });

  describe('Split button options', () => {
    it('returns correct mergeRequestGroup structure', async () => {
      wrapper = createComponent();
      await waitForPromises();

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

  describe('when mergeRequestsEnabled=false', () => {
    beforeEach(async () => {
      wrapper = createComponent({
        namespaceMergeRequestsEnabledHandler: jest.fn().mockResolvedValue({
          data: { workspace: { id: 'gid://gitlab/Group/33', mergeRequestsEnabled: false } },
        }),
      });
      await waitForPromises();
    });

    it('renders "Create branch" for button text', () => {
      expect(findMainButton().text()).toBe('Create branch');
    });

    it('only shows "Create branch" dropdown group', () => {
      const groups = findDropdownGroups();
      const branchGroup = groups.at(0);

      expect(groups).toHaveLength(1);
      expect(branchGroup.props('group').name).toBe('Branch');
      expect(branchGroup.props('group').items).toEqual([
        expect.objectContaining({
          text: 'Create branch',
          extraAttrs: { 'data-testid': 'create-branch-dropdown-button' },
        }),
      ]);
    });
  });

  describe('namespaceMergeRequestsEnabledQuery', () => {
    describe('when namespaceMergeRequestsEnabledQuery is loading', () => {
      it('shows loading indicator on the main button', () => {
        wrapper = createComponent();

        expect(findMainButton().props('loading')).toBe(true);
      });
    });

    describe('when namespaceMergeRequestsEnabledQuery fails', () => {
      it('only shows "Create branch"', async () => {
        wrapper = createComponent({
          namespaceMergeRequestsEnabledHandler: jest.fn().mockRejectedValue('Error!'),
        });
        await waitForPromises();

        expect(findMainButton().text()).toBe('Create branch');
        expect(findDropdownGroups()).toHaveLength(1);
        expect(findDropdownGroups().at(0).props('group').items).toEqual([
          expect.objectContaining({ text: 'Create branch' }),
        ]);
      });
    });
  });
});
