import Vue, { nextTick } from 'vue';
import { GlBadge } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinks from '~/work_items/components/work_item_links/work_item_links.vue';
import changeWorkItemParentMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { WIDGET_TYPE_HIERARCHY } from '~/work_items/constants';
import getWorkItemLinksQuery from '~/work_items/graphql/work_item_links.query.graphql';
import {
  workItemHierarchyResponse,
  workItemHierarchyEmptyResponse,
  workItemHierarchyNoUpdatePermissionResponse,
  changeWorkItemParentMutationResponse,
} from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemLinks', () => {
  let wrapper;
  let mockApollo;

  const PARENT_ID = 'gid://gitlab/WorkItem/1';
  const WORK_ITEM_ID = 'gid://gitlab/WorkItem/2';

  const $toast = {
    show: jest.fn(),
  };

  const mutationChangeParentHandler = jest
    .fn()
    .mockResolvedValue(changeWorkItemParentMutationResponse);

  const createComponent = async ({
    data = {},
    response = workItemHierarchyResponse,
    mutationHandler = mutationChangeParentHandler,
  } = {}) => {
    mockApollo = createMockApollo([
      [getWorkItemLinksQuery, jest.fn().mockResolvedValue(response)],
      [changeWorkItemParentMutation, mutationHandler],
    ]);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getWorkItemLinksQuery,
      variables: {
        id: PARENT_ID,
      },
      data: response.data,
    });

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

  const findToggleButton = () => wrapper.findByTestId('toggle-links');
  const findLinksBody = () => wrapper.findByTestId('links-body');
  const findEmptyState = () => wrapper.findByTestId('links-empty');
  const findToggleAddFormButton = () => wrapper.findByTestId('toggle-add-form');
  const findAddLinksForm = () => wrapper.findByTestId('add-links-form');
  const findFirstLinksMenu = () => wrapper.findByTestId('links-menu');

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

  it('expands on click toggle button', async () => {
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
      await createComponent({ response: workItemHierarchyEmptyResponse });
    });

    it('displays empty state if there are no children', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  it('renders all hierarchy widget children', () => {
    expect(findLinksBody().exists()).toBe(true);

    const children = wrapper.findAll('[data-testid="links-child"]');

    expect(children).toHaveLength(4);
    expect(children.at(0).findComponent(GlBadge).text()).toBe('Open');
    expect(findFirstLinksMenu().exists()).toBe(true);
  });

  describe('when no permission to update', () => {
    beforeEach(async () => {
      await createComponent({ response: workItemHierarchyNoUpdatePermissionResponse });
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
      mockApollo.clients.defaultClient.cache.readQuery = jest.fn(
        () => workItemHierarchyResponse.data,
      );

      mockApollo.clients.defaultClient.cache.writeQuery = jest.fn();
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

    it('updates the cache when mutation succeeds', async () => {
      findFirstLinksMenu().vm.$emit('removeChild');

      await waitForPromises();

      // Remove the work item from parent's children
      const resp = cloneDeep(workItemHierarchyResponse);
      const index = resp.data.workItem.widgets
        .find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)
        .children.nodes.findIndex((child) => child.id === WORK_ITEM_ID);
      resp.data.workItem.widgets
        .find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)
        .children.nodes.splice(index, 1);

      expect(mockApollo.clients.defaultClient.cache.writeQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          query: expect.anything(),
          variables: { id: PARENT_ID },
          data: resp.data,
        }),
      );
    });
  });
});
