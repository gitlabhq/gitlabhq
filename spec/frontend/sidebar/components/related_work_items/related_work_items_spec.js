import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlCollapse, GlIcon, GlLink, GlLoadingIcon, GlPopover } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import WorkItemDetailPanel from '~/work_items/components/work_item_detail_panel.vue';
import MRRelatedWorkItems from '~/sidebar/components/related_work_items/related_work_items.vue';
import RelatedWorkItemsAddForm from '~/sidebar/components/related_work_items/related_work_items_add_form.vue';
import mergeRequestRelatedWorkItemsQuery from '~/sidebar/queries/merge_request_related_work_items.query.graphql';
import createMergeRequestWorkItemRelationMutation from '~/sidebar/queries/create_merge_request_work_item_relation.mutation.graphql';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

Vue.use(VueApollo);

const MOCK_MERGE_REQUEST_ID = 'gid://gitlab/MergeRequest/1';

let workItemCounter = 0;
const mockLinkedItem = ({ title, linkType }) => {
  workItemCounter += 1;
  return {
    linkType,
    workItem: {
      id: `gid://gitlab/WorkItem/${workItemCounter + 100}`,
      iid: String(workItemCounter),
      title,
      webUrl: `/group/project/-/work_items/${workItemCounter}`,
      webPath: `/group/project/-/work_items/${workItemCounter}`,
      namespace: {
        id: 'gid://gitlab/Project/7',
        fullPath: 'group/project',
        __typename: 'Namespace',
      },
      __typename: 'WorkItem',
    },
    __typename: 'LinkedWorkItem',
  };
};

const mockRelationItem = ({ title, linkType }) => {
  const { workItem } = mockLinkedItem({ title, linkType });
  return {
    id: `gid://gitlab/MergeRequestsClosingIssues/${workItemCounter}`,
    linkType,
    fromMrDescription: true,
    workItem,
    __typename: 'MergeRequestWorkItemRelation',
  };
};

const closingItem1 = mockLinkedItem({ title: 'Fix bug', linkType: 'CLOSES' });
const closingItem2 = mockLinkedItem({ title: 'Update docs', linkType: 'CLOSES' });
const mentionedItem = mockLinkedItem({ title: 'Refactor code', linkType: 'MENTIONED' });

const MOCK_MERGE_REQUEST_IID = '1';

const buildQueryResponse = (
  linkedWorkItems = [],
  { adminMergeRequest = true, includePermissions = true, workItemRelations = [] } = {},
) => ({
  data: {
    mergeRequest: {
      id: MOCK_MERGE_REQUEST_ID,
      iid: MOCK_MERGE_REQUEST_IID,
      title: 'Fix the bug',
      reference: 'group/project!1',
      ...(includePermissions
        ? {
            userPermissions: {
              adminMergeRequest,
              __typename: 'MergeRequestPermissions',
            },
          }
        : {}),
      workItemRelations: {
        nodes: workItemRelations,
        __typename: 'MergeRequestWorkItemRelationConnection',
      },
      linkedWorkItems,
      __typename: 'MergeRequest',
    },
  },
});

const buildRelationsResponse = (nodes = [], options = {}) =>
  buildQueryResponse([], { ...options, workItemRelations: nodes });

const buildCreateMutationResponse = (workItemRelations = [], errors = []) => ({
  data: {
    mergeRequestCreateWorkItemRelations: {
      errors,
      workItemRelations,
      __typename: 'MergeRequestCreateWorkItemRelationsPayload',
    },
  },
});

describe('MRRelatedWorkItems', () => {
  let wrapper;
  const showToast = jest.fn();

  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findDetailPanel = () => wrapper.findComponent(WorkItemDetailPanel);
  const findAllLinks = () => wrapper.findAllComponents(GlLink);
  const findNoneText = () => wrapper.find('.hide-collapsed.gl-text-subtle');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAddButton = () => wrapper.findComponentByTestId('add-work-item-button');
  const findAddForm = () => wrapper.findComponent(RelatedWorkItemsAddForm);

  const createComponent = ({
    queryHandler = jest.fn().mockResolvedValue(buildQueryResponse()),
    provide = {},
  } = {}) => {
    wrapper = shallowMountExtended(MRRelatedWorkItems, {
      apolloProvider: createMockApollo([[mergeRequestRelatedWorkItemsQuery, queryHandler]]),
      provide: {
        fullPath: 'group/project',
        id: '1',
        ...provide,
      },
      mocks: {
        $toast: { show: showToast },
      },
      stubs: {
        GlCollapse,
      },
    });
  };

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders loading icon while query is in progress', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render "None" text while loading', () => {
      expect(findNoneText().exists()).toBe(false);
    });

    it('does not render info icon while loading', () => {
      expect(findInfoIcon().exists()).toBe(false);
    });
  });

  it('displays an alert when query is rejected', async () => {
    createComponent({
      queryHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
    });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: 'Something went wrong while fetching related work items.',
    });
  });

  describe('with no items', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not render loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders "None" text', () => {
      expect(findNoneText().text()).toBe('None');
    });

    it('renders info icon', () => {
      expect(findInfoIcon().exists()).toBe(true);
      expect(findInfoIcon().attributes('name')).toBe('information-o');
    });

    it('renders popover with closing patterns link', () => {
      const popover = findPopover();
      expect(popover.exists()).toBe(true);
      expect(popover.attributes('target')).toBe('related-work-items-info');
    });

    it('does not render collapse button', () => {
      expect(findCollapseButton().exists()).toBe(false);
    });
  });

  it('filters out null workItem entries and renders valid items', async () => {
    const nullWorkItem = { linkType: 'CLOSES', workItem: null, __typename: 'LinkedWorkItem' };

    createComponent({
      queryHandler: jest
        .fn()
        .mockResolvedValue(buildQueryResponse([closingItem1, nullWorkItem, mentionedItem])),
    });
    await waitForPromises();

    const links = findAllLinks();
    expect(links).toHaveLength(2);
    expect(links.at(0).text()).toBe('Fix bug');
    expect(links.at(1).text()).toBe('Refactor code');
  });

  describe('with items (not exceeding collapse threshold)', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: jest
          .fn()
          .mockResolvedValue(buildQueryResponse([closingItem1, mentionedItem])),
      });
      await waitForPromises();
    });

    it('does not render "None" text', () => {
      expect(wrapper.text()).not.toContain('None');
    });

    it('does not render info icon', () => {
      expect(wrapper.find('#related-work-items-info').exists()).toBe(false);
    });

    it('renders closing and mentioned section labels', () => {
      expect(wrapper.text()).toContain('Closing');
      expect(wrapper.text()).toContain('Mentioned');
    });

    it('renders work item links', () => {
      const links = findAllLinks();
      expect(links).toHaveLength(2);
      expect(links.at(0).text()).toBe('Fix bug');
      expect(links.at(1).text()).toBe('Refactor code');
    });

    it('sets popover data attributes on links', () => {
      const link = findAllLinks().at(0);
      expect(link.classes()).toContain('has-popover');
      expect(link.attributes('data-reference-type')).toBe('work_item');
      expect(link.attributes('data-iid')).toBe('1');
      expect(link.attributes('data-project-path')).toBe('group/project');
    });

    it('does not show collapse button when items <= 2', () => {
      expect(findCollapseButton().exists()).toBe(false);
    });

    it('shows items directly without collapsing', () => {
      expect(findCollapse().props('visible')).toBe(true);
    });
  });

  describe('with items exceeding collapse threshold (> 2)', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: jest
          .fn()
          .mockResolvedValue(buildQueryResponse([closingItem1, closingItem2, mentionedItem])),
      });
      await waitForPromises();
    });

    it('renders collapsed summary link', () => {
      const summaryLink = findAllLinks().at(0);
      expect(summaryLink.text()).toBe('Closing 2, Mentioned 1');
    });

    it('starts in collapsed state', () => {
      expect(findCollapse().props('visible')).toBe(false);
    });

    it('expands when summary link is clicked', async () => {
      findAllLinks().at(0).vm.$emit('click');
      await nextTick();

      expect(findCollapse().props('visible')).toBe(true);
    });

    it('shows collapse button when expanded', async () => {
      findAllLinks().at(0).vm.$emit('click');
      await nextTick();

      const collapseBtn = findCollapseButton();
      expect(collapseBtn.exists()).toBe(true);
      expect(collapseBtn.attributes('icon')).toBe('chevron-down');
      expect(collapseBtn.attributes('title')).toBe('Collapse work items');
    });

    it('collapses when collapse button is clicked', async () => {
      findAllLinks().at(0).vm.$emit('click');
      await nextTick();

      findCollapseButton().vm.$emit('click');
      await nextTick();

      expect(findCollapse().props('visible')).toBe(false);
    });
  });

  describe('drawer interaction', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();
    });

    it('opens drawer when link is clicked', async () => {
      findAllLinks().at(0).vm.$emit('click', { preventDefault: jest.fn(), metaKey: false });
      await nextTick();

      expect(findDetailPanel().props('open')).toBe(true);
      expect(findDetailPanel().props('activeItem')).toMatchObject({
        iid: '1',
        title: 'Fix bug',
      });
    });

    it('does not open drawer on meta+click', async () => {
      findAllLinks().at(0).vm.$emit('click', { preventDefault: jest.fn(), metaKey: true });
      await nextTick();

      expect(findDetailPanel().props('open')).toBe(false);
    });

    it('does not open drawer on ctrl+click', async () => {
      findAllLinks().at(0).vm.$emit('click', { preventDefault: jest.fn(), ctrlKey: true });
      await nextTick();

      expect(findDetailPanel().props('open')).toBe(false);
    });

    it('closes drawer on close event', async () => {
      findAllLinks().at(0).vm.$emit('click', { preventDefault: jest.fn(), metaKey: false });
      await nextTick();
      expect(findDetailPanel().props('open')).toBe(true);

      findDetailPanel().vm.$emit('close');
      await nextTick();
      expect(findDetailPanel().props('open')).toBe(false);
    });
  });

  describe('checkDrawerParams', () => {
    const validItem = { id: 101, iid: '1', full_path: 'group/project' };
    const encodedParam = btoa(JSON.stringify(validItem));

    it('opens drawer when valid show param is present', async () => {
      getParameterByName.mockReturnValue(encodedParam);

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(findDetailPanel().props('open')).toBe(true);
      expect(findDetailPanel().props('activeItem')).toMatchObject({
        iid: '1',
        title: 'Fix bug',
      });
    });

    it('removes param when item is not found', async () => {
      getParameterByName.mockReturnValue(
        btoa(JSON.stringify({ id: 999, iid: '999', full_path: 'group/project' })),
      );
      removeParams.mockReturnValue('http://test.host/');

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(updateHistory).toHaveBeenCalledWith({
        url: 'http://test.host/',
      });
      expect(findDetailPanel().props('open')).toBe(false);
    });

    it('removes param when base64 is invalid', async () => {
      getParameterByName.mockReturnValue('not-valid-base64!!!');
      removeParams.mockReturnValue('http://test.host/');

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(updateHistory).toHaveBeenCalled();
      expect(findDetailPanel().props('open')).toBe(false);
    });

    it('sets activeItem to null when no show param', async () => {
      getParameterByName.mockReturnValue(null);

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(findDetailPanel().props('open')).toBe(false);
    });

    it('responds to popstate events', async () => {
      getParameterByName.mockReturnValue(null);

      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildQueryResponse([closingItem1])),
      });
      await waitForPromises();

      expect(findDetailPanel().props('open')).toBe(false);

      getParameterByName.mockReturnValue(encodedParam);
      window.dispatchEvent(new PopStateEvent('popstate'));
      await nextTick();

      expect(findDetailPanel().props('open')).toBe(true);
    });
  });

  describe('when the user can administer the merge request', () => {
    const glFeatures = { explicitMrWorkItemRelations: true };

    beforeEach(async () => {
      createComponent({
        queryHandler: jest
          .fn()
          .mockResolvedValue(buildQueryResponse([], { adminMergeRequest: true })),
        provide: { glFeatures },
      });
      await waitForPromises();
    });

    it('renders the add work item button', () => {
      expect(findAddButton().exists()).toBe(true);
    });

    it('renders the add form hidden by default', () => {
      expect(findAddForm().exists()).toBe(true);
      expect(findAddForm().props('visible')).toBe(false);
    });

    it('passes the merge request title and reference to the add form', () => {
      expect(findAddForm().props('mergeRequestTitle')).toBe('Fix the bug');
      expect(findAddForm().props('mergeRequestReference')).toBe('group/project!1');
    });

    it('shows the add form when the add button is clicked', async () => {
      findAddButton().vm.$emit('click');
      await nextTick();

      expect(findAddForm().props('visible')).toBe(true);
    });

    it('hides the add form when it emits hide', async () => {
      findAddButton().vm.$emit('click');
      await nextTick();
      expect(findAddForm().props('visible')).toBe(true);

      findAddForm().vm.$emit('hide');
      await nextTick();

      expect(findAddForm().props('visible')).toBe(false);
    });

    it('hides the add form when it emits link', async () => {
      findAddButton().vm.$emit('click');
      await nextTick();
      expect(findAddForm().props('visible')).toBe(true);

      findAddForm().vm.$emit('link');
      await nextTick();

      expect(findAddForm().props('visible')).toBe(false);
    });
  });

  describe('when the `explicitMrWorkItemRelations` feature flag is enabled', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: jest
          .fn()
          .mockResolvedValue(buildQueryResponse([], { adminMergeRequest: false })),
        provide: { glFeatures: { explicitMrWorkItemRelations: true } },
      });
      await waitForPromises();
    });

    it('does not render the add work item button', () => {
      expect(findAddButton().exists()).toBe(false);
    });

    it('does not render the add form', () => {
      expect(findAddForm().exists()).toBe(false);
    });
  });

  describe('when the `explicitMrWorkItemRelations` feature flag is disabled', () => {
    it('queries with explicitMrWorkItemRelations set to false', async () => {
      const queryHandler = jest.fn().mockResolvedValue(buildQueryResponse());
      createComponent({
        queryHandler,
        provide: { glFeatures: { explicitMrWorkItemRelations: false } },
      });
      await waitForPromises();

      expect(queryHandler).toHaveBeenCalledWith(
        expect.objectContaining({ explicitMrWorkItemRelations: false }),
      );
    });

    it('does not render the add work item button or form when permissions are not fetched', async () => {
      createComponent({
        queryHandler: jest
          .fn()
          .mockResolvedValue(buildQueryResponse([], { includePermissions: false })),
        provide: { glFeatures: { explicitMrWorkItemRelations: false } },
      });
      await waitForPromises();

      expect(findAddButton().exists()).toBe(false);
      expect(findAddForm().exists()).toBe(false);
    });
  });

  describe('when the feature flag is enabled and relations are present', () => {
    const closingRelation = mockRelationItem({ title: 'Fix bug', linkType: 'CLOSES' });
    const relatedRelation = mockRelationItem({ title: 'Investigate flake', linkType: 'RELATED' });
    const mentionedRelation = mockRelationItem({ title: 'Refactor code', linkType: 'MENTIONED' });

    const createWithRelations = (nodes) =>
      createComponent({
        queryHandler: jest.fn().mockResolvedValue(buildRelationsResponse(nodes)),
        provide: { glFeatures: { explicitMrWorkItemRelations: true } },
      });

    it('consumes workItemRelations instead of linkedWorkItems', async () => {
      createWithRelations([closingRelation]);
      await waitForPromises();

      expect(findNoneText().exists()).toBe(false);
      expect(findAllLinks().at(0).text()).toBe('Fix bug');
    });

    it('renders closing, related, and mentioned section labels', async () => {
      createWithRelations([closingRelation, relatedRelation, mentionedRelation]);
      await waitForPromises();

      expect(wrapper.text()).toContain('Closing');
      expect(wrapper.text()).toContain('Related');
      expect(wrapper.text()).toContain('Mentioned');
    });

    it('renders a collapsed summary covering all three relationship types', async () => {
      createWithRelations([closingRelation, relatedRelation, mentionedRelation]);
      await waitForPromises();

      expect(findAllLinks().at(0).text()).toBe('Closing 1, Related 1, Mentioned 1');
    });
  });

  describe('creating a related work item', () => {
    const newRelation = mockRelationItem({ title: 'New related item', linkType: 'RELATED' });
    let mutationHandler;

    const createWithMutation = ({
      mutationResponse = buildCreateMutationResponse([newRelation]),
    } = {}) => {
      mutationHandler = jest.fn().mockResolvedValue(mutationResponse);
      wrapper = shallowMountExtended(MRRelatedWorkItems, {
        apolloProvider: createMockApollo([
          [
            mergeRequestRelatedWorkItemsQuery,
            jest.fn().mockResolvedValue(buildRelationsResponse([])),
          ],
          [createMergeRequestWorkItemRelationMutation, mutationHandler],
        ]),
        provide: {
          fullPath: 'group/project',
          id: '1',
          glFeatures: { explicitMrWorkItemRelations: true },
        },
        mocks: {
          $toast: { show: showToast },
        },
        stubs: { GlCollapse },
      });
    };

    beforeEach(async () => {
      createWithMutation();
      await waitForPromises();
    });

    it('calls the create mutation with the selected work items and link type', async () => {
      findAddForm().vm.$emit('link', {
        workItems: [newRelation.workItem],
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(mutationHandler).toHaveBeenCalledWith({
        projectPath: 'group/project',
        iid: MOCK_MERGE_REQUEST_IID,
        workItemIds: [newRelation.workItem.id],
        linkType: 'RELATED',
      });
    });

    it('adds the created relation to the rendered list', async () => {
      expect(findNoneText().exists()).toBe(true);

      findAddForm().vm.$emit('link', {
        workItems: [newRelation.workItem],
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(wrapper.text()).toContain('Related');
      expect(findAllLinks().at(0).text()).toBe('New related item');
    });

    it('hides the add form after linking', async () => {
      findAddForm().vm.$emit('link', {
        workItems: [newRelation.workItem],
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(findAddForm().props('visible')).toBe(false);
    });

    it('shows a toast after linking succeeds', async () => {
      findAddForm().vm.$emit('link', {
        workItems: [newRelation.workItem],
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('Linked item added');
    });

    it('shows a pluralized toast when multiple items are linked', async () => {
      findAddForm().vm.$emit('link', {
        workItems: [
          newRelation.workItem,
          { ...newRelation.workItem, id: 'gid://gitlab/WorkItem/999' },
        ],
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('Linked items added');
    });

    it('shows a toast when a new work item is created and linked', async () => {
      findAddForm().vm.$emit('created', {
        workItem: newRelation.workItem,
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith('Linked item added');
    });

    it('shows an alert and captures the error when the mutation request fails', async () => {
      const error = new Error('Network error');
      mutationHandler.mockRejectedValueOnce(error);

      findAddForm().vm.$emit('link', {
        workItems: [newRelation.workItem],
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while linking the work item.',
        error,
        captureError: true,
      });
      expect(showToast).not.toHaveBeenCalled();
    });

    it('keeps the add form open when linking fails so the user can retry', async () => {
      mutationHandler.mockRejectedValueOnce(new Error('Network error'));

      findAddButton().vm.$emit('click');
      await nextTick();
      expect(findAddForm().props('visible')).toBe(true);

      findAddForm().vm.$emit('link', {
        workItems: [newRelation.workItem],
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(findAddForm().props('visible')).toBe(true);
    });

    it('shows an alert and does not link when the mutation returns errors', async () => {
      createWithMutation({
        mutationResponse: buildCreateMutationResponse([], ['Work item could not be linked.']),
      });
      await waitForPromises();

      findAddForm().vm.$emit('link', {
        workItems: [newRelation.workItem],
        linkType: 'RELATED',
      });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Work item could not be linked.',
      });
      expect(showToast).not.toHaveBeenCalled();
      expect(findNoneText().exists()).toBe(true);
    });

    it('does not call the mutation when no work items are selected', async () => {
      findAddForm().vm.$emit('link', { workItems: [], linkType: 'RELATED' });
      await waitForPromises();

      expect(mutationHandler).not.toHaveBeenCalled();
    });
  });
});
