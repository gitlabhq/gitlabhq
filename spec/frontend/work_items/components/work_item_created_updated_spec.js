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
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { mockAssignees, workItemByIidResponseFactory } from '../mock_data';

describe('WorkItemCreatedUpdated component', () => {
  let wrapper;
  let successHandler;

  Vue.use(VueApollo);

  const findCreatedAt = () => wrapper.find('[data-testid="work-item-created"]');

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
  } = {}) => {
    const workItemQueryResponse = workItemByIidResponseFactory({
      author,
      updatedAt,
      confidential,
      discussionLocked,
    });

    successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);

    wrapper = shallowMount(WorkItemCreatedUpdated, {
      apolloProvider: createMockApollo([[workItemByIidQuery, successHandler]]),
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

  it('calls the successHandler when the query is completed', async () => {
    await createComponent();

    expect(successHandler).toHaveBeenCalled();
    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('shows loading icon when the query is still loading', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('skips calling the work item query when workItemIid is not defined', async () => {
    await createComponent({ workItemIid: null });

    expect(successHandler).not.toHaveBeenCalled();
  });

  it('shows work item type metadata with type and icon', async () => {
    await createComponent();

    const {
      data: { workspace: { workItem } = {} },
    } = workItemByIidResponseFactory();

    expect(findWorkItemTypeIcon().props()).toMatchObject({
      showText: true,
      workItemIconName: workItem.workItemType.iconName,
      workItemType: workItem.workItemType.name,
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
