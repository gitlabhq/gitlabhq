import Vue, { nextTick } from 'vue';
import { GlButton, GlIcon, GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SidebarEventHub from '~/sidebar/event_hub';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import WorkItemLinks from '~/work_items/components/work_item_links/work_item_links.vue';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import changeWorkItemParentMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import getWorkItemLinksQuery from '~/work_items/graphql/work_item_links.query.graphql';
import {
  workItemHierarchyResponse,
  workItemHierarchyEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
  changeWorkItemParentMutationResponse,
  workItemQueryResponse,
} from '../../mock_data';

Vue.use(VueApollo);

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

  const findChildren = () => wrapper.findAll('[data-testid="links-child"]');

  const createComponent = async ({
    data = {},
    fetchHandler = jest.fn().mockResolvedValue(workItemHierarchyResponse),
    mutationHandler = mutationChangeParentHandler,
  } = {}) => {
    mockApollo = createMockApollo(
      [
        [getWorkItemLinksQuery, fetchHandler],
        [changeWorkItemParentMutation, mutationHandler],
        [workItemQuery, childWorkItemQueryHandler],
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
      },
      propsData: { issuableId: 1 },
      apolloProvider: mockApollo,
      mocks: {
        $toast,
      },
    });

    await waitForPromises();
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findToggleButton = () => wrapper.findByTestId('toggle-links');
  const findLinksBody = () => wrapper.findByTestId('links-body');
  const findEmptyState = () => wrapper.findByTestId('links-empty');
  const findToggleAddFormButton = () => wrapper.findByTestId('toggle-add-form');
  const findAddLinksForm = () => wrapper.findByTestId('add-links-form');
  const findFirstLinksMenu = () => wrapper.findByTestId('links-menu');
  const findChildrenCount = () => wrapper.findByTestId('children-count');

  beforeEach(async () => {
    await createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mockApollo = null;
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
    it('displays form on click add button and hides form on cancel', async () => {
      findToggleAddFormButton().vm.$emit('click');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(true);

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

    expect(findChildren()).toHaveLength(4);
    expect(findFirstLinksMenu().exists()).toBe(true);
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

  it('renders widget child icon and tooltip', () => {
    expect(findChildren().at(0).findComponent(GlIcon).props('name')).toBe('issue-open-m');
    expect(findChildren().at(1).findComponent(GlIcon).props('name')).toBe('issue-close');
  });

  it('renders confidentiality icon when child item is confidential', () => {
    const children = wrapper.findAll('[data-testid="links-child"]');
    const confidentialIcon = children.at(0).find('[data-testid="confidential-icon"]');

    expect(confidentialIcon.exists()).toBe(true);
    expect(confidentialIcon.props('name')).toBe('eye-slash');
  });

  it('displays number if children', () => {
    expect(findChildrenCount().exists()).toBe(true);

    expect(findChildrenCount().text()).toContain('4');
  });

  it('refetches child items when `confidentialityUpdated` event is emitted on SidebarEventhub', async () => {
    const fetchHandler = jest.fn().mockResolvedValue(workItemHierarchyResponse);
    await createComponent({
      fetchHandler,
    });
    await waitForPromises();

    SidebarEventHub.$emit('confidentialityUpdated');
    await nextTick();

    // First call is done on component mount.
    // Second call is done on confidentialityUpdated event.
    expect(fetchHandler).toHaveBeenCalledTimes(2);
  });

  describe('when no permission to update', () => {
    beforeEach(async () => {
      await createComponent({
        fetchHandler: jest.fn().mockResolvedValue(workItemHierarchyNoUpdatePermissionResponse),
      });
    });

    it('does not display button to toggle Add form', () => {
      expect(findToggleAddFormButton().exists()).toBe(false);
    });

    it('does not display link menu on children', () => {
      expect(findFirstLinksMenu().exists()).toBe(false);
    });
  });

  describe('remove child', () => {
    beforeEach(async () => {
      await createComponent({ mutationHandler: mutationChangeParentHandler });
    });

    it('calls correct mutation with correct variables', async () => {
      findFirstLinksMenu().vm.$emit('removeChild');

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
      findFirstLinksMenu().vm.$emit('removeChild');

      await waitForPromises();

      expect($toast.show).toHaveBeenCalledWith('Child removed', {
        action: { onClick: expect.anything(), text: 'Undo' },
      });
    });

    it('renders correct number of children after removal', async () => {
      expect(findChildren()).toHaveLength(4);

      findFirstLinksMenu().vm.$emit('removeChild');
      await waitForPromises();

      expect(findChildren()).toHaveLength(3);
    });
  });

  describe('prefetching child items', () => {
    beforeEach(async () => {
      await createComponent();
    });

    const findChildLink = () => findChildren().at(0).findComponent(GlButton);

    it('does not fetch the child work item before hovering work item links', () => {
      expect(childWorkItemQueryHandler).not.toHaveBeenCalled();
    });

    it('fetches the child work item if link is hovered for 250+ ms', async () => {
      findChildLink().vm.$emit('mouseover');
      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();

      expect(childWorkItemQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/WorkItem/2',
      });
    });

    it('does not fetch the child work item if link is hovered for less than 250 ms', async () => {
      findChildLink().vm.$emit('mouseover');
      jest.advanceTimersByTime(200);
      findChildLink().vm.$emit('mouseout');
      await waitForPromises();

      expect(childWorkItemQueryHandler).not.toHaveBeenCalled();
    });
  });
});
