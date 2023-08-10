import { GlAvatarLink, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemCreatedUpdated from '~/work_items/components/work_item_created_updated.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { workItemByIidResponseFactory, mockAssignees } from '../mock_data';

describe('WorkItemCreatedUpdated component', () => {
  let wrapper;
  let successHandler;

  Vue.use(VueApollo);

  const findCreatedAt = () => wrapper.find('[data-testid="work-item-created"]');
  const findUpdatedAt = () => wrapper.find('[data-testid="work-item-updated"]');

  const findCreatedAtText = () => findCreatedAt().text().replace(/\s+/g, ' ');
  const findWorkItemTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);
  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = async ({
    workItemIid = '1',
    author = null,
    updatedAt,
    confidential = false,
    updateInProgress = false,
  } = {}) => {
    const workItemQueryResponse = workItemByIidResponseFactory({
      author,
      updatedAt,
      confidential,
    });

    successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);

    wrapper = shallowMount(WorkItemCreatedUpdated, {
      apolloProvider: createMockApollo([[workItemByIidQuery, successHandler]]),
      provide: {
        fullPath: '/some/project',
      },
      propsData: { workItemIid, updateInProgress },
      stubs: {
        GlAvatarLink,
        GlSprintf,
      },
    });

    await waitForPromises();
  };

  it('skips the work item query when workItemIid is not defined', async () => {
    await createComponent({ workItemIid: null });

    expect(successHandler).not.toHaveBeenCalled();
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

    it('does not render badge when the work item is confidential', async () => {
      await createComponent({ confidential: false });

      expect(findConfidentialityBadge().exists()).toBe(false);
    });

    it('shows loading icon badge when the work item is confidential', async () => {
      await createComponent({ updateInProgress: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });
});
