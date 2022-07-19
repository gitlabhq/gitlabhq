import Vue from 'vue';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemLinksMenu from '~/work_items/components/work_item_links/work_item_links_menu.vue';
import changeWorkItemParentMutation from '~/work_items/graphql/change_work_item_parent_link.mutation.graphql';
import getWorkItemLinksQuery from '~/work_items/graphql/work_item_links.query.graphql';
import { WIDGET_TYPE_HIERARCHY } from '~/work_items/constants';
import { workItemHierarchyResponse, changeWorkItemParentMutationResponse } from '../../mock_data';

Vue.use(VueApollo);

const PARENT_ID = 'gid://gitlab/WorkItem/1';
const WORK_ITEM_ID = 'gid://gitlab/WorkItem/3';

describe('WorkItemLinksMenu', () => {
  let wrapper;
  let mockApollo;

  const $toast = {
    show: jest.fn(),
  };

  const createComponent = async ({
    data = {},
    mutationHandler = jest.fn().mockResolvedValue(changeWorkItemParentMutationResponse),
  } = {}) => {
    mockApollo = createMockApollo([
      [getWorkItemLinksQuery, jest.fn().mockResolvedValue(workItemHierarchyResponse)],
      [changeWorkItemParentMutation, mutationHandler],
    ]);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getWorkItemLinksQuery,
      variables: {
        id: PARENT_ID,
      },
      data: workItemHierarchyResponse.data,
    });

    wrapper = shallowMountExtended(WorkItemLinksMenu, {
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        workItemId: WORK_ITEM_ID,
        parentWorkItemId: PARENT_ID,
      },
      apolloProvider: mockApollo,
      mocks: {
        $toast,
      },
    });

    await waitForPromises();
  };

  const findDropdown = () => wrapper.find(GlDropdown);
  const findRemoveDropdownItem = () => wrapper.find(GlDropdownItem);

  beforeEach(async () => {
    await createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mockApollo = null;
  });

  it('renders dropdown and dropdown items', () => {
    expect(findDropdown().exists()).toBe(true);
    expect(findRemoveDropdownItem().exists()).toBe(true);
  });

  it('calls correct mutation with correct variables', async () => {
    const mutationHandler = jest.fn().mockResolvedValue(changeWorkItemParentMutationResponse);

    createComponent({ mutationHandler });

    findRemoveDropdownItem().vm.$emit('click');

    await waitForPromises();

    expect(mutationHandler).toHaveBeenCalledWith({
      id: WORK_ITEM_ID,
      parentId: null,
    });
  });

  it('shows toast when mutation succeeds', async () => {
    const mutationHandler = jest.fn().mockResolvedValue(changeWorkItemParentMutationResponse);

    createComponent({ mutationHandler });

    findRemoveDropdownItem().vm.$emit('click');

    await waitForPromises();

    expect($toast.show).toHaveBeenCalledWith('Child removed', {
      action: { onClick: expect.anything(), text: 'Undo' },
    });
  });

  it('updates the cache when mutation succeeds', async () => {
    const mutationHandler = jest.fn().mockResolvedValue(changeWorkItemParentMutationResponse);

    createComponent({ mutationHandler });

    mockApollo.clients.defaultClient.cache.readQuery = jest.fn(
      () => workItemHierarchyResponse.data,
    );

    mockApollo.clients.defaultClient.cache.writeQuery = jest.fn();

    findRemoveDropdownItem().vm.$emit('click');

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
