import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import issueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import { resolvers } from '~/graphql_shared/issuable_client';
import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';
import WorkItemLinks from '~/work_items/components/work_item_links/work_item_links.vue';
import WorkItemChildrenWrapper from '~/work_items/components/work_item_links/work_item_children_wrapper.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import { FORM_TYPES } from '~/work_items/constants';
import changeWorkItemParentMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import {
  getIssueDetailsResponse,
  workItemHierarchyResponse,
  workItemHierarchyEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
  changeWorkItemParentMutationResponse,
  workItemByIidResponseFactory,
  workItemQueryResponse,
  mockWorkItemCommentNote,
  childrenWorkItems,
} from '../../mock_data';

Vue.use(VueApollo);

const showModal = jest.fn();

describe('WorkItemLinks', () => {
  let wrapper;
  let mockApollo;

  const WORK_ITEM_ID = 'gid://gitlab/WorkItem/2';

  const $toast = {
    show: jest.fn(),
  };

  const mutationChangeParentHandler = jest
    .fn()
    .mockResolvedValue(changeWorkItemParentMutationResponse);
  const childWorkItemByIidHandler = jest.fn().mockResolvedValue(workItemByIidResponseFactory());
  const responseWithAddChildPermission = jest.fn().mockResolvedValue(workItemHierarchyResponse);
  const responseWithoutAddChildPermission = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory({ adminParentLink: false }));

  const createComponent = async ({
    data = {},
    fetchHandler = responseWithAddChildPermission,
    mutationHandler = mutationChangeParentHandler,
    issueDetailsQueryHandler = jest.fn().mockResolvedValue(getIssueDetailsResponse()),
    hasIterationsFeature = false,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [workItemQuery, fetchHandler],
        [changeWorkItemParentMutation, mutationHandler],
        [issueDetailsQuery, issueDetailsQueryHandler],
        [workItemByIidQuery, childWorkItemByIidHandler],
      ],
      resolvers,
      { addTypename: true },
    );

    wrapper = shallowMountExtended(WorkItemLinks, {
      data() {
        return {
          ...data,
        };
      },
      provide: {
        projectPath: 'project/path',
        hasIterationsFeature,
        reportAbusePath: '/report/abuse/path',
      },
      propsData: { issuableId: 1 },
      apolloProvider: mockApollo,
      mocks: {
        $toast,
      },
      stubs: {
        WorkItemDetailModal: stubComponent(WorkItemDetailModal, {
          methods: {
            show: showModal,
          },
        }),
      },
    });

    wrapper.vm.$refs.wrapper.show = jest.fn();

    await waitForPromises();
  };

  const findWidgetWrapper = () => wrapper.findComponent(WidgetWrapper);
  const findEmptyState = () => wrapper.findByTestId('links-empty');
  const findToggleFormDropdown = () => wrapper.findByTestId('toggle-form');
  const findToggleAddFormButton = () => wrapper.findByTestId('toggle-add-form');
  const findToggleCreateFormButton = () => wrapper.findByTestId('toggle-create-form');
  const findAddLinksForm = () => wrapper.findByTestId('add-links-form');
  const findChildrenCount = () => wrapper.findByTestId('children-count');
  const findWorkItemDetailModal = () => wrapper.findComponent(WorkItemDetailModal);
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);
  const findWorkItemLinkChildrenWrapper = () => wrapper.findComponent(WorkItemChildrenWrapper);

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
      createComponent({ fetchHandler: workItemFetchHandler });
      await waitForPromises();

      expect(findToggleFormDropdown().exists()).toBe(value);
    },
  );

  describe('add link form', () => {
    it('displays add work item form on click add dropdown then add existing button and hides form on cancel', async () => {
      await createComponent();
      findToggleFormDropdown().vm.$emit('click');
      findToggleAddFormButton().vm.$emit('click');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(true);
      expect(findAddLinksForm().props('formType')).toBe(FORM_TYPES.add);

      findAddLinksForm().vm.$emit('cancel');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(false);
    });

    it('displays create work item form on click add dropdown then create button and hides form on cancel', async () => {
      await createComponent();
      findToggleFormDropdown().vm.$emit('click');
      findToggleCreateFormButton().vm.$emit('click');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(true);
      expect(findAddLinksForm().props('formType')).toBe(FORM_TYPES.create);

      findAddLinksForm().vm.$emit('cancel');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(false);
    });

    it('adds work item child from the form', async () => {
      const workItem = {
        ...workItemQueryResponse.data.workItem,
        id: 'gid://gitlab/WorkItem/11',
      };
      await createComponent();
      findToggleFormDropdown().vm.$emit('click');
      findToggleCreateFormButton().vm.$emit('click');
      await nextTick();

      expect(findWorkItemLinkChildrenWrapper().props().children).toHaveLength(4);

      findAddLinksForm().vm.$emit('addWorkItemChild', workItem);
      await waitForPromises();

      expect(findWorkItemLinkChildrenWrapper().props().children).toHaveLength(5);
    });
  });

  describe('when no child links', () => {
    beforeEach(async () => {
      await createComponent({
        fetchHandler: jest.fn().mockResolvedValue(workItemHierarchyEmptyResponse),
      });
    });

    it('displays empty state if there are no children', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  it('renders hierarchy widget children container', async () => {
    await createComponent();

    expect(findWorkItemLinkChildrenWrapper().exists()).toBe(true);
    expect(findWorkItemLinkChildrenWrapper().props().children).toHaveLength(4);
  });

  it('shows an alert when list loading fails', async () => {
    const errorMessage = 'Some error';
    await createComponent({
      fetchHandler: jest.fn().mockRejectedValue(new Error(errorMessage)),
    });

    expect(findWidgetWrapper().props('error')).toBe(errorMessage);
  });

  it('displays number of children', async () => {
    await createComponent();

    expect(findChildrenCount().exists()).toBe(true);
    expect(findChildrenCount().text()).toContain('4');
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

  describe('remove child', () => {
    let firstChild;

    beforeEach(async () => {
      await createComponent({ mutationHandler: mutationChangeParentHandler });

      [firstChild] = childrenWorkItems;
    });

    it('calls correct mutation with correct variables', async () => {
      findWorkItemLinkChildrenWrapper().vm.$emit('removeChild', firstChild.id);

      await waitForPromises();

      expect(mutationChangeParentHandler).toHaveBeenCalledWith({
        input: {
          id: WORK_ITEM_ID,
          hierarchyWidget: {
            parentId: null,
          },
        },
      });
    });

    it('shows toast when mutation succeeds', async () => {
      findWorkItemLinkChildrenWrapper().vm.$emit('removeChild', firstChild.id);

      await waitForPromises();

      expect($toast.show).toHaveBeenCalledWith('Child removed', {
        action: { onClick: expect.anything(), text: 'Undo' },
      });
    });

    it('renders correct number of children after removal', async () => {
      expect(findWorkItemLinkChildrenWrapper().props().children).toHaveLength(4);

      findWorkItemLinkChildrenWrapper().vm.$emit('removeChild', firstChild.id);
      await waitForPromises();

      expect(findWorkItemLinkChildrenWrapper().props().children).toHaveLength(3);
    });
  });

  describe('when parent item is confidential', () => {
    it('passes correct confidentiality status to form', async () => {
      await createComponent({
        issueDetailsQueryHandler: jest
          .fn()
          .mockResolvedValue(getIssueDetailsResponse({ confidential: true })),
      });
      findToggleFormDropdown().vm.$emit('click');
      findToggleAddFormButton().vm.$emit('click');
      await nextTick();

      expect(findAddLinksForm().props('parentConfidential')).toBe(true);
    });
  });

  it('starts prefetching work item by iid if URL contains work_item_iid query parameter', async () => {
    setWindowLocation('?work_item_iid=5');
    await createComponent();

    expect(childWorkItemByIidHandler).toHaveBeenCalledWith({
      iid: '5',
      fullPath: 'project/path',
    });
  });

  it('does not open the modal if work item iid URL parameter is not found in child items', async () => {
    setWindowLocation('?work_item_iid=555');
    await createComponent();

    expect(showModal).not.toHaveBeenCalled();
    expect(findWorkItemDetailModal().props('workItemIid')).toBe(null);
  });

  it('opens the modal if work item iid URL parameter is found in child items', async () => {
    setWindowLocation('?work_item_iid=2');
    await createComponent();

    expect(showModal).toHaveBeenCalled();
    expect(findWorkItemDetailModal().props('workItemIid')).toBe('2');
  });

  describe('abuse category selector', () => {
    beforeEach(async () => {
      setWindowLocation('?work_item_id=2');
      await createComponent();
    });

    it('should not be visible by default', () => {
      expect(findAbuseCategorySelector().exists()).toBe(false);
    });

    it('should be visible when the work item modal emits `openReportAbuse` event', async () => {
      findWorkItemDetailModal().vm.$emit('openReportAbuse', mockWorkItemCommentNote);

      await nextTick();

      expect(findAbuseCategorySelector().exists()).toBe(true);

      findAbuseCategorySelector().vm.$emit('close-drawer');

      await nextTick();

      expect(findAbuseCategorySelector().exists()).toBe(false);
    });
  });
});
