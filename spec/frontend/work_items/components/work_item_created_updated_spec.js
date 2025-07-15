import { GlAvatarLink, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import WorkItemCreatedUpdated from '~/work_items/components/work_item_created_updated.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { workItemByIidResponseFactory, mockAssignees } from 'ee_else_ce_jest/work_items/mock_data';

describe('WorkItemCreatedUpdated component', () => {
  let wrapper;
  let successHandler;

  Vue.use(VueApollo);

  const findCreatedAt = () => wrapper.find('[data-testid="work-item-created"]');

  const findCreatedAtText = () => findCreatedAt().text().replace(/\s+/g, ' ');
  const findWorkItemTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);
  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkItemStateBadge = () => wrapper.findComponent(WorkItemStateBadge);

  const createComponent = async ({
    workItemIid = '1',
    author = null,
    hidden = false,
    imported = false,
    updatedAt,
    confidential = false,
    discussionLocked = false,
    updateInProgress = false,
    movedToWorkItemUrl = null,
    duplicatedToWorkItemUrl = null,
  } = {}) => {
    const workItemQueryResponse = workItemByIidResponseFactory({
      author,
      hidden,
      imported,
      updatedAt,
      confidential,
      discussionLocked,
      movedToWorkItemUrl,
      duplicatedToWorkItemUrl,
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

  describe('WorkItemStateBadge props', () => {
    it('passes URL props correctly when they exist', async () => {
      // We'll never populate all of these attributes because
      // a work item can only have one closed reason.
      // For simplicity we're passing all of them to easily assert
      // that the props are passed correctly.
      //
      // Leaves out promotedToEpicUrl because it's only available in
      // the EE work items query which is not using in FOSS_ONLY mode
      const workItemAttributes = {
        movedToWorkItemUrl: 'http://example.com/moved',
        duplicatedToWorkItemUrl: 'http://example.com/duplicated',
      };

      await createComponent(workItemAttributes);

      const stateBadgeProps = findWorkItemStateBadge().props();
      Object.entries(workItemAttributes).forEach(([prop, url]) => {
        expect(stateBadgeProps[prop]).toBe(url);
      });
    });
  });

  it('shows work item type metadata with type and icon', async () => {
    await createComponent();

    const {
      data: { workspace: { workItem } = {} },
    } = workItemByIidResponseFactory();

    expect(findWorkItemTypeIcon().props()).toMatchObject({
      showText: true,
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

  describe('hidden badge', () => {
    it('renders when the work item is hidden', async () => {
      await createComponent({ hidden: true });

      expect(findHiddenBadge().exists()).toBe(true);
    });

    it('does not render when the work item is not hidden', async () => {
      await createComponent({ hidden: false });

      expect(findHiddenBadge().exists()).toBe(false);
    });
  });

  describe('imported badge', () => {
    it('renders when the work item is imported', async () => {
      await createComponent({ imported: true });

      expect(findImportedBadge().exists()).toBe(true);
    });

    it('does not render when the work item is not imported', async () => {
      await createComponent({ imported: false });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });
});
