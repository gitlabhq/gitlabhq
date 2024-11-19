import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';

import { createAlert } from '~/alert';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import issueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';

import { resolvers } from '~/graphql_shared/issuable_client';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemLinks from '~/work_items/components/work_item_links/work_item_links.vue';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import WorkItemAbuseModal from '~/work_items/components/work_item_abuse_modal.vue';
import WorkItemMoreActions from '~/work_items/components/shared/work_item_more_actions.vue';
import {
  FORM_TYPES,
  WORKITEM_LINKS_SHOWLABELS_LOCALSTORAGEKEY,
  WORKITEM_TREE_SHOWCLOSED_LOCALSTORAGEKEY,
} from '~/work_items/constants';
import getWorkItemTreeQuery from '~/work_items/graphql/work_item_tree.query.graphql';

import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import * as utils from '~/work_items/utils';
import {
  getIssueDetailsResponse,
  workItemHierarchyTreeResponse,
  workItemHierarchyPaginatedTreeResponse,
  workItemHierarchyTreeEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
  workItemByIidResponseFactory,
  workItemHierarchyTreeSingleClosedItemResponse,
  mockWorkItemCommentNote,
} from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const showModal = jest.fn();

describe('WorkItemLinks', () => {
  let wrapper;
  let mockApollo;

  const responseWithAddChildPermission = jest.fn().mockResolvedValue(workItemHierarchyTreeResponse);
  const responseWithoutAddChildPermission = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ adminParentLink: false }));

  const createComponent = async ({
    fetchHandler = responseWithAddChildPermission,
    issueDetailsQueryHandler = jest.fn().mockResolvedValue(getIssueDetailsResponse()),
    hasIterationsFeature = false,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [getWorkItemTreeQuery, fetchHandler],
        [issueDetailsQuery, issueDetailsQueryHandler],
      ],
      resolvers,
    );

    wrapper = shallowMountExtended(WorkItemLinks, {
      provide: {
        fullPath: 'project/path',
        hasIterationsFeature,
        reportAbusePath: '/report/abuse/path',
      },
      propsData: {
        issuableId: 1,
        issuableIid: 1,
      },
      apolloProvider: mockApollo,
      stubs: {
        WorkItemDetailModal: stubComponent(WorkItemDetailModal, {
          methods: {
            show: showModal,
          },
        }),
        CrudComponent,
      },
    });

    await waitForPromises();
  };

  const findErrorMessage = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findByTestId('crud-empty');
  const findToggleFormDropdown = () => wrapper.findByTestId('toggle-form');
  const findToggleAddFormButton = () => wrapper.findByTestId('toggle-add-form');
  const findToggleCreateFormButton = () => wrapper.findByTestId('toggle-create-form');
  const findAddLinksForm = () => wrapper.findByTestId('add-links-form');
  const findChildrenCount = () => wrapper.findByTestId('crud-count');
  const findWorkItemDetailModal = () => wrapper.findComponent(WorkItemDetailModal);
  const findAbuseCategoryModal = () => wrapper.findComponent(WorkItemAbuseModal);
  const findWorkItemLinkChildrenWrapper = () => wrapper.findComponent(WorkItemChildrenWrapper);
  const findMoreActions = () => wrapper.findComponent(WorkItemMoreActions);

  afterEach(() => {
    mockApollo = null;
    setWindowLocation('');
  });

  it.each`
    expectedAssertion    | workItemFetchHandler                 | value
    ${'renders'}         | ${responseWithAddChildPermission}    | ${true}
    ${'does not render'} | ${responseWithoutAddChildPermission} | ${false}
  `(
    '$expectedAssertion "Add" button in hierarchy widget header when "userPermissions.adminParentLink" is $value',
    async ({ workItemFetchHandler, value }) => {
      await createComponent({ fetchHandler: workItemFetchHandler });

      expect(findToggleFormDropdown().exists()).toBe(value);
    },
  );

  describe('add link form', () => {
    it('displays add work item form on click add dropdown then add existing button and hides form on cancel', async () => {
      await createComponent();
      findToggleFormDropdown().vm.$emit('action');
      findToggleAddFormButton().vm.$emit('action');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(true);
      expect(findAddLinksForm().props('formType')).toBe(FORM_TYPES.add);

      findAddLinksForm().vm.$emit('cancel');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(false);
    });

    it('displays create work item form on click add dropdown then create button and hides form on cancel', async () => {
      await createComponent();
      findToggleFormDropdown().vm.$emit('action');
      findToggleCreateFormButton().vm.$emit('action');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(true);
      expect(findAddLinksForm().props('formType')).toBe(FORM_TYPES.create);

      findAddLinksForm().vm.$emit('cancel');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(false);
    });
  });

  describe('when no child links', () => {
    beforeEach(async () => {
      await createComponent({
        fetchHandler: jest.fn().mockResolvedValue(workItemHierarchyTreeEmptyResponse),
      });
    });

    it('displays empty state if there are no children', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  it('renders hierarchy widget children container', async () => {
    await createComponent();

    expect(findWorkItemLinkChildrenWrapper().exists()).toBe(true);
    expect(findWorkItemLinkChildrenWrapper().props().children).toHaveLength(1);
  });

  it('shows an alert when list loading fails', async () => {
    const errorMessage = 'Some error';
    await createComponent({
      fetchHandler: jest.fn().mockRejectedValue(new Error(errorMessage)),
    });

    expect(findErrorMessage().text()).toBe(errorMessage);
  });

  it('displays number of children', async () => {
    await createComponent();

    expect(findChildrenCount().exists()).toBe(true);
    expect(findChildrenCount().text()).toContain('1');
  });

  describe('when no permission to update', () => {
    beforeEach(async () => {
      await createComponent({
        fetchHandler: jest.fn().mockResolvedValue(workItemHierarchyNoUpdatePermissionResponse),
      });
    });

    it('does not display button to toggle Add form', () => {
      expect(findToggleFormDropdown().exists()).toBe(false);
    });

    it('does not display link menu on children', () => {
      expect(findWorkItemLinkChildrenWrapper().props('canUpdate')).toBe(false);
    });
  });

  describe('when parent item is confidential', () => {
    it('passes correct confidentiality status to form', async () => {
      await createComponent({
        issueDetailsQueryHandler: jest
          .fn()
          .mockResolvedValue(getIssueDetailsResponse({ confidential: true })),
      });
      findToggleFormDropdown().vm.$emit('action');
      findToggleAddFormButton().vm.$emit('action');
      await nextTick();

      expect(findAddLinksForm().props('parentConfidential')).toBe(true);
    });
  });

  it('does not open the modal if work item iid URL parameter is not found in child items', async () => {
    setWindowLocation('?work_item_iid=555');
    await createComponent();

    expect(showModal).not.toHaveBeenCalled();
    expect(findWorkItemDetailModal().props('workItemIid')).toBe(null);
  });

  it('opens the modal if work item iid URL parameter is found in child items', async () => {
    setWindowLocation('?work_item_iid=37');
    await createComponent();

    expect(showModal).toHaveBeenCalled();
    expect(findWorkItemDetailModal().props('workItemIid')).toBe('37');
  });

  it('opens the modal if work item id URL parameter is found in child items', async () => {
    setWindowLocation('?show=31');
    await createComponent();

    expect(showModal).toHaveBeenCalled();
    expect(findWorkItemDetailModal().props('workItemId')).toBe('gid://gitlab/WorkItem/31');
    expect(findWorkItemDetailModal().props('workItemIid')).toBe('37');
  });

  describe('abuse category selector', () => {
    beforeEach(async () => {
      setWindowLocation('?work_item_id=2');
      await createComponent();
    });

    it('should not be visible by default', () => {
      expect(findAbuseCategoryModal().exists()).toBe(false);
    });

    it('should be visible when the work item modal emits `openReportAbuse` event', async () => {
      findWorkItemDetailModal().vm.$emit('openReportAbuse', mockWorkItemCommentNote);

      await nextTick();

      expect(findAbuseCategoryModal().exists()).toBe(true);

      findAbuseCategoryModal().vm.$emit('close-modal');

      await nextTick();

      expect(findAbuseCategoryModal().exists()).toBe(false);
    });
  });

  it('calls the project work item query', () => {
    createComponent();

    expect(responseWithAddChildPermission).toHaveBeenCalled();
  });

  describe('pagination', () => {
    const findWorkItemChildrenLoadMore = () => wrapper.findByTestId('work-item-load-more');
    let workItemTreeQueryHandler;

    beforeEach(async () => {
      workItemTreeQueryHandler = jest
        .fn()
        .mockResolvedValue(workItemHierarchyPaginatedTreeResponse);

      await createComponent({
        fetchHandler: workItemTreeQueryHandler,
      });
    });

    it('shows work-item-children-load-more component when hasNextPage is true and node is expanded', () => {
      const loadMore = findWorkItemChildrenLoadMore();
      expect(loadMore.exists()).toBe(true);
      expect(loadMore.props('fetchNextPageInProgress')).toBe(false);
    });

    it('queries next page children when work-item-children-load-more emits "fetch-next-page"', async () => {
      findWorkItemChildrenLoadMore().vm.$emit('fetch-next-page');
      await waitForPromises();

      expect(workItemTreeQueryHandler).toHaveBeenCalled();
    });

    it('shows alert message when fetching next page fails', async () => {
      jest.spyOn(wrapper.vm.$apollo.queries.workItem, 'fetchMore').mockRejectedValueOnce({});
      findWorkItemChildrenLoadMore().vm.$emit('fetch-next-page');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.any(Object),
        message: 'Something went wrong while fetching children.',
      });
    });
  });

  describe('more actions', () => {
    useLocalStorageSpy();

    beforeEach(async () => {
      jest.spyOn(utils, 'getToggleFromLocalStorage');
      jest.spyOn(utils, 'saveToggleToLocalStorage');
      await createComponent();
    });

    afterEach(() => {
      localStorage.clear();
    });

    it('renders the `WorkItemMoreActions` component', async () => {
      await createComponent();

      expect(findMoreActions().exists()).toBe(true);
    });

    it('does not render `View on a roadmap` action', async () => {
      await createComponent();

      expect(findMoreActions().props('showViewRoadmapAction')).toBe(false);
    });

    it('toggles `showLabels` when `toggle-show-labels` is emitted', async () => {
      await createComponent();

      expect(findWorkItemLinkChildrenWrapper().props('showLabels')).toBe(true);

      findMoreActions().vm.$emit('toggle-show-labels');

      await nextTick();

      expect(findWorkItemLinkChildrenWrapper().props('showLabels')).toBe(false);

      findMoreActions().vm.$emit('toggle-show-labels');

      await nextTick();

      expect(findWorkItemLinkChildrenWrapper().props('showLabels')).toBe(true);
    });

    it('calls saveToggleToLocalStorage on toggle-show-labels', () => {
      findMoreActions().vm.$emit('toggle-show-labels');
      expect(utils.saveToggleToLocalStorage).toHaveBeenCalled();
    });

    it('calls getToggleFromLocalStorage on mount for toggle-show-labels', () => {
      expect(utils.getToggleFromLocalStorage).toHaveBeenCalledWith(
        WORKITEM_LINKS_SHOWLABELS_LOCALSTORAGEKEY,
      );
    });

    it('calls saveToggleToLocalStorage on toggle-show-closed', () => {
      findMoreActions().vm.$emit('toggle-show-closed');
      expect(utils.saveToggleToLocalStorage).toHaveBeenCalled();
    });

    it('calls getToggleFromLocalStorage on mount for toggle-show-closed', () => {
      expect(utils.getToggleFromLocalStorage).toHaveBeenCalledWith(
        WORKITEM_TREE_SHOWCLOSED_LOCALSTORAGEKEY,
      );
    });
  });

  it('displays no child items open message', async () => {
    await createComponent({
      fetchHandler: jest.fn().mockResolvedValue(workItemHierarchyTreeSingleClosedItemResponse),
    });

    expect(wrapper.findByTestId('work-item-no-child-items-open').exists()).toBe(false);

    await findMoreActions().vm.$emit('toggle-show-closed');

    expect(wrapper.findByTestId('work-item-no-child-items-open').text()).toBe(
      'No child items are currently open.',
    );
  });
});
