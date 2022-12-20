import Vue, { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import issueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import WorkItemLinks from '~/work_items/components/work_item_links/work_item_links.vue';
import WorkItemLinkChild from '~/work_items/components/work_item_links/work_item_link_child.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { FORM_TYPES } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import changeWorkItemParentMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import getWorkItemLinksQuery from '~/work_items/graphql/work_item_links.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import {
  workItemHierarchyResponse,
  workItemHierarchyEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
  changeWorkItemParentMutationResponse,
  workItemQueryResponse,
  projectWorkItemResponse,
} from '../../mock_data';

Vue.use(VueApollo);

const issueDetailsResponse = (confidential = false) => ({
  data: {
    workspace: {
      id: 'gid://gitlab/Project/1',
      issuable: {
        id: 'gid://gitlab/Issue/4',
        confidential,
        iteration: {
          id: 'gid://gitlab/Iteration/1124',
          title: null,
          startDate: '2022-06-22',
          dueDate: '2022-07-19',
          webUrl: 'http://127.0.0.1:3000/groups/gitlab-org/-/iterations/1124',
          iterationCadence: {
            id: 'gid://gitlab/Iterations::Cadence/1101',
            title: 'Quod voluptates quidem ea eaque eligendi ex corporis.',
            __typename: 'IterationCadence',
          },
          __typename: 'Iteration',
        },
        milestone: {
          dueDate: null,
          expired: false,
          id: 'gid://gitlab/Milestone/28',
          title: 'v2.0',
          __typename: 'Milestone',
        },
        __typename: 'Issue',
      },
      __typename: 'Project',
    },
  },
});
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
    issueDetailsQueryHandler = jest.fn().mockResolvedValue(issueDetailsResponse()),
    hasIterationsFeature = false,
    fetchByIid = false,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [getWorkItemLinksQuery, fetchHandler],
        [changeWorkItemParentMutation, mutationHandler],
        [workItemQuery, childWorkItemQueryHandler],
        [issueDetailsQuery, issueDetailsQueryHandler],
        [workItemByIidQuery, childWorkItemByIidHandler],
      ],
      {},
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
        iid: '1',
        hasIterationsFeature,
        glFeatures: {
          useIidInWorkItemsPath: fetchByIid,
        },
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

    await waitForPromises();
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findToggleButton = () => wrapper.findByTestId('toggle-links');
  const findLinksBody = () => wrapper.findByTestId('links-body');
  const findEmptyState = () => wrapper.findByTestId('links-empty');
  const findToggleFormDropdown = () => wrapper.findByTestId('toggle-form');
  const findToggleAddFormButton = () => wrapper.findByTestId('toggle-add-form');
  const findToggleCreateFormButton = () => wrapper.findByTestId('toggle-create-form');
  const findWorkItemLinkChildItems = () => wrapper.findAllComponents(WorkItemLinkChild);
  const findFirstWorkItemLinkChild = () => findWorkItemLinkChildItems().at(0);
  const findAddLinksForm = () => wrapper.findByTestId('add-links-form');
  const findChildrenCount = () => wrapper.findByTestId('children-count');

  beforeEach(async () => {
    await createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mockApollo = null;
    setWindowLocation('');
  });

  it('is expanded by default', () => {
    expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
    expect(findLinksBody().exists()).toBe(true);
  });

  it('collapses on click toggle button', async () => {
    findToggleButton().vm.$emit('click');
    await nextTick();

    expect(findToggleButton().props('icon')).toBe('chevron-lg-down');
    expect(findLinksBody().exists()).toBe(false);
  });

  describe('add link form', () => {
    it('displays add work item form on click add dropdown then add existing button and hides form on cancel', async () => {
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
      findToggleFormDropdown().vm.$emit('click');
      findToggleCreateFormButton().vm.$emit('click');
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
        fetchHandler: jest.fn().mockResolvedValue(workItemHierarchyEmptyResponse),
      });
    });

    it('displays empty state if there are no children', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  it('renders all hierarchy widget children', () => {
    expect(findLinksBody().exists()).toBe(true);

    expect(findWorkItemLinkChildItems()).toHaveLength(4);
  });

  it('shows alert when list loading fails', async () => {
    const errorMessage = 'Some error';
    await createComponent({
      fetchHandler: jest.fn().mockRejectedValue(new Error(errorMessage)),
    });

    await nextTick();

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe(errorMessage);
  });

  it('displays number if children', () => {
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
        issueDetailsQueryHandler: jest.fn().mockResolvedValue(issueDetailsResponse(true)),
      });
      findToggleFormDropdown().vm.$emit('click');
      findToggleAddFormButton().vm.$emit('click');
      await nextTick();

      expect(findAddLinksForm().props('parentConfidential')).toBe(true);
    });
  });

  describe('when work item is fetched by id', () => {
    describe('prefetching child items', () => {
      let firstChild;

      beforeEach(async () => {
        await createComponent();

        firstChild = findFirstWorkItemLinkChild();
      });

      it('does not fetch the child work item by id before hovering work item links', () => {
        expect(childWorkItemQueryHandler).not.toHaveBeenCalled();
      });

      it('fetches the child work item by id if link is hovered for 250+ ms', async () => {
        firstChild.vm.$emit('mouseover', firstChild.vm.childItem.id);
        jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
        await waitForPromises();

        expect(childWorkItemQueryHandler).toHaveBeenCalledWith({
          id: 'gid://gitlab/WorkItem/2',
        });
      });

      it('does not fetch the child work item by id if link is hovered for less than 250 ms', async () => {
        firstChild.vm.$emit('mouseover', firstChild.vm.childItem.id);
        jest.advanceTimersByTime(200);
        firstChild.vm.$emit('mouseout', firstChild.vm.childItem.id);
        await waitForPromises();

        expect(childWorkItemQueryHandler).not.toHaveBeenCalled();
      });

      it('does not fetch work item by iid if link is hovered for 250+ ms', async () => {
        firstChild.vm.$emit('mouseover', firstChild.vm.childItem.id);
        jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
        await waitForPromises();

        expect(childWorkItemByIidHandler).not.toHaveBeenCalled();
      });
    });

    it('starts prefetching work item by id if URL contains work item id', async () => {
      setWindowLocation('?work_item_id=5');
      await createComponent();

      expect(childWorkItemQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/WorkItem/5',
      });
    });

    it('does not open the modal if work item id URL parameter is not found in child items', async () => {
      setWindowLocation('?work_item_id=555');
      await createComponent();

      expect(showModal).not.toHaveBeenCalled();
      expect(wrapper.findComponent(WorkItemDetailModal).props('workItemId')).toBe(null);
    });

    it('opens the modal if work item id URL parameter is found in child items', async () => {
      setWindowLocation('?work_item_id=2');
      await createComponent();

      expect(showModal).toHaveBeenCalled();
      expect(wrapper.findComponent(WorkItemDetailModal).props('workItemId')).toBe(
        'gid://gitlab/WorkItem/2',
      );
    });
  });

  describe('when work item is fetched by iid', () => {
    describe('prefetching child items', () => {
      let firstChild;

      beforeEach(async () => {
        setWindowLocation('?iid_path=true');
        await createComponent({ fetchByIid: true });

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
      await createComponent({ fetchByIid: true });

      expect(childWorkItemByIidHandler).toHaveBeenCalledWith({
        iid: '5',
        fullPath: 'project/path',
      });
    });
  });

  it('does not open the modal if work item iid URL parameter is not found in child items', async () => {
    setWindowLocation('?work_item_iid=555&iid_path=true');
    await createComponent({ fetchByIid: true });

    expect(showModal).not.toHaveBeenCalled();
    expect(wrapper.findComponent(WorkItemDetailModal).props('workItemIid')).toBe(null);
  });

  it('opens the modal if work item iid URL parameter is found in child items', async () => {
    setWindowLocation('?work_item_iid=2&iid_path=true');
    await createComponent({ fetchByIid: true });

    expect(showModal).toHaveBeenCalled();
    expect(wrapper.findComponent(WorkItemDetailModal).props('workItemIid')).toBe('2');
  });
});
