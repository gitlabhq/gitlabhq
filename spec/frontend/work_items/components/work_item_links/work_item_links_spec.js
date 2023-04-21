import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import issueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import { resolvers } from '~/graphql_shared/issuable_client';
import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';
import WorkItemLinks from '~/work_items/components/work_item_links/work_item_links.vue';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { FORM_TYPES } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import changeWorkItemParentMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import getWorkItemLinksQuery from '~/work_items/graphql/work_item_links.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import {
  getIssueDetailsResponse,
  workItemHierarchyResponse,
  workItemHierarchyEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
  changeWorkItemParentMutationResponse,
  workItemQueryResponse,
  projectWorkItemResponse,
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

  const childWorkItemQueryHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const childWorkItemByIidHandler = jest.fn().mockResolvedValue(projectWorkItemResponse);

  const createComponent = async ({
    data = {},
    fetchHandler = jest.fn().mockResolvedValue(workItemHierarchyResponse),
    mutationHandler = mutationChangeParentHandler,
    issueDetailsQueryHandler = jest.fn().mockResolvedValue(getIssueDetailsResponse()),
    hasIterationsFeature = false,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [getWorkItemLinksQuery, fetchHandler],
        [changeWorkItemParentMutation, mutationHandler],
        [workItemQuery, childWorkItemQueryHandler],
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
  const findWorkItemLinkChildItems = () => wrapper.findAllComponents(WorkItemLinkChild);
  const findFirstWorkItemLinkChild = () => findWorkItemLinkChildItems().at(0);
  const findAddLinksForm = () => wrapper.findByTestId('add-links-form');
  const findChildrenCount = () => wrapper.findByTestId('children-count');

  afterEach(() => {
    mockApollo = null;
    setWindowLocation('');
  });

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

      expect(findWorkItemLinkChildItems()).toHaveLength(4);

      findAddLinksForm().vm.$emit('addWorkItemChild', workItem);
      await waitForPromises();

      expect(findWorkItemLinkChildItems()).toHaveLength(5);
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

  it('renders all hierarchy widget children', async () => {
    await createComponent();

    expect(findWorkItemLinkChildItems()).toHaveLength(4);
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
      expect(findWorkItemLinkChildItems().at(0).props('canUpdate')).toBe(false);
    });
  });

  describe('remove child', () => {
    let firstChild;

    beforeEach(async () => {
      await createComponent({ mutationHandler: mutationChangeParentHandler });

      firstChild = findFirstWorkItemLinkChild();
    });

    it('calls correct mutation with correct variables', async () => {
      firstChild.vm.$emit('removeChild', firstChild.vm.childItem.id);

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
      firstChild.vm.$emit('removeChild', firstChild.vm.childItem.id);

      await waitForPromises();

      expect($toast.show).toHaveBeenCalledWith('Child removed', {
        action: { onClick: expect.anything(), text: 'Undo' },
      });
    });

    it('renders correct number of children after removal', async () => {
      expect(findWorkItemLinkChildItems()).toHaveLength(4);

      firstChild.vm.$emit('removeChild', firstChild.vm.childItem.id);
      await waitForPromises();

      expect(findWorkItemLinkChildItems()).toHaveLength(3);
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

  describe('prefetching child items', () => {
    let firstChild;

    beforeEach(async () => {
      setWindowLocation('?iid_path=true');
      await createComponent();

      firstChild = findFirstWorkItemLinkChild();
    });

    it('does not fetch the child work item by iid before hovering work item links', () => {
      expect(childWorkItemByIidHandler).not.toHaveBeenCalled();
    });

    it('fetches the child work item by iid if link is hovered for 250+ ms', async () => {
      firstChild.vm.$emit('mouseover', firstChild.vm.childItem.id);
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();

      expect(childWorkItemByIidHandler).toHaveBeenCalledWith({
        fullPath: 'project/path',
        iid: '2',
      });
    });

    it('does not fetch the child work item by iid if link is hovered for less than 250 ms', async () => {
      firstChild.vm.$emit('mouseover', firstChild.vm.childItem.id);
      jest.advanceTimersByTime(200);
      firstChild.vm.$emit('mouseout', firstChild.vm.childItem.id);
      await waitForPromises();

      expect(childWorkItemByIidHandler).not.toHaveBeenCalled();
    });

    it('does not fetch work item by id if link is hovered for 250+ ms', async () => {
      firstChild.vm.$emit('mouseover', firstChild.vm.childItem.id);
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();

      expect(childWorkItemQueryHandler).not.toHaveBeenCalled();
    });
  });

  it('starts prefetching work item by iid if URL contains work item id', async () => {
    setWindowLocation('?work_item_iid=5&iid_path=true');
    await createComponent();

    expect(childWorkItemByIidHandler).toHaveBeenCalledWith({
      iid: '5',
      fullPath: 'project/path',
    });
  });

  it('does not open the modal if work item iid URL parameter is not found in child items', async () => {
    setWindowLocation('?work_item_iid=555&iid_path=true');
    await createComponent();

    expect(showModal).not.toHaveBeenCalled();
    expect(wrapper.findComponent(WorkItemDetailModal).props('workItemIid')).toBe(null);
  });

  it('opens the modal if work item iid URL parameter is found in child items', async () => {
    setWindowLocation('?work_item_iid=2&iid_path=true');
    await createComponent();

    expect(showModal).toHaveBeenCalled();
    expect(wrapper.findComponent(WorkItemDetailModal).props('workItemIid')).toBe('2');
  });
});
