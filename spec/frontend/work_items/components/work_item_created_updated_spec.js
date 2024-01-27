import { GlAvatarLink, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import WorkItemCreatedUpdated from '~/work_items/components/work_item_created_updated.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import groupWorkItemByIidQuery from '~/work_items/graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import {
  groupWorkItemByIidResponseFactory,
  mockAssignees,
  workItemByIidResponseFactory,
} from '../mock_data';

describe('WorkItemCreatedUpdated component', () => {
  let wrapper;
  let successHandler;
  let groupSuccessHandler;

  Vue.use(VueApollo);

  const findCreatedAt = () => wrapper.find('[data-testid="work-item-created"]');
  const findUpdatedAt = () => wrapper.find('[data-testid="work-item-updated"]');

  const findCreatedAtText = () => findCreatedAt().text().replace(/\s+/g, ' ');
  const findWorkItemTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);
  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = async ({
    workItemIid = '1',
    author = null,
    updatedAt,
    confidential = false,
    discussionLocked = false,
    updateInProgress = false,
    isGroup = false,
  } = {}) => {
    const workItemQueryResponse = workItemByIidResponseFactory({
      author,
      updatedAt,
      confidential,
      discussionLocked,
    });
    const groupWorkItemQueryResponse = groupWorkItemByIidResponseFactory({
      author,
      updatedAt,
      confidential,
      discussionLocked,
    });

    successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
    groupSuccessHandler = jest.fn().mockResolvedValue(groupWorkItemQueryResponse);

    wrapper = shallowMount(WorkItemCreatedUpdated, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, successHandler],
        [groupWorkItemByIidQuery, groupSuccessHandler],
      ]),
      provide: {
        isGroup,
      },
      propsData: {
        fullPath: '/some/project',
        workItemIid,
        updateInProgress,
      },
      stubs: {
        GlAvatarLink,
        GlSprintf,
      },
    });

    await waitForPromises();
  };

  describe('when project context', () => {
    it('calls the project work item query', async () => {
      await createComponent();

      expect(successHandler).toHaveBeenCalled();
    });

    it('skips calling the group work item query', async () => {
      await createComponent();

      expect(groupSuccessHandler).not.toHaveBeenCalled();
    });

    it('skips calling the project work item query when workItemIid is not defined', async () => {
      await createComponent({ workItemIid: null });

      expect(successHandler).not.toHaveBeenCalled();
    });
  });

  describe('when group context', () => {
    it('skips calling the project work item query', async () => {
      await createComponent({ isGroup: true });

      expect(successHandler).not.toHaveBeenCalled();
    });

    it('calls the group work item query', async () => {
      await createComponent({ isGroup: true });

      expect(groupSuccessHandler).toHaveBeenCalled();
    });

    it('skips calling the group work item query when workItemIid is not defined', async () => {
      await createComponent({ isGroup: true, workItemIid: null });

      expect(groupSuccessHandler).not.toHaveBeenCalled();
    });
  });

  it('shows work item type metadata with type and icon', async () => {
    await createComponent();

    const {
      data: { workspace: { workItems } = {} },
    } = workItemByIidResponseFactory();

    expect(findWorkItemTypeIcon().props()).toMatchObject({
      showText: true,
      workItemIconName: workItems.nodes[0].workItemType.iconName,
      workItemType: workItems.nodes[0].workItemType.name,
    });
  });

  it('shows author name and link', async () => {
    const author = mockAssignees[0];
    await createComponent({ author });

    expect(findCreatedAtText()).toBe(`created by ${author.name}`);
  });

  it('shows created time when author is null', async () => {
    await createComponent({ author: null });

    expect(findCreatedAtText()).toBe('created');
  });

  it('shows updated time', async () => {
    await createComponent();

    expect(findUpdatedAt().exists()).toBe(true);
  });

  it('does not show updated time for new work items', async () => {
    await createComponent({ updatedAt: null });

    expect(findUpdatedAt().exists()).toBe(false);
  });

  describe('confidential badge', () => {
    it('renders badge when the work item is confidential', async () => {
      await createComponent({ confidential: true });

      expect(findConfidentialityBadge().exists()).toBe(true);
    });

    it('does not render badge when the work item is not confidential', async () => {
      await createComponent({ confidential: false });

      expect(findConfidentialityBadge().exists()).toBe(false);
    });

    it('shows loading icon badge when the work item is confidential', async () => {
      await createComponent({ updateInProgress: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('locked badge', () => {
    it('renders when the work item is locked', async () => {
      await createComponent({ discussionLocked: true });

      expect(findLockedBadge().exists()).toBe(true);
    });

    it('does not render when the work item is not locked', async () => {
      await createComponent({ discussionLocked: false });

      expect(findLockedBadge().exists()).toBe(false);
    });
  });
});
