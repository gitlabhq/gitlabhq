import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlToggle } from '@gitlab/ui';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';
import WorkItemRelationships from '~/work_items/components/work_item_relationships/work_item_relationships.vue';
import WorkItemRelationshipList from '~/work_items/components/work_item_relationships/work_item_relationship_list.vue';
import WorkItemAddRelationshipForm from '~/work_items/components/work_item_relationships/work_item_add_relationship_form.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import removeLinkedItemsMutation from '~/work_items/graphql/remove_linked_items.mutation.graphql';

import {
  workItemByIidResponseFactory,
  mockLinkedItems,
  mockBlockingLinkedItem,
  removeLinkedWorkItemResponse,
} from '../../mock_data';

describe('WorkItemRelationships', () => {
  Vue.use(VueApollo);

  let wrapper;
  const emptyLinkedWorkItemsQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory());
  const removeLinkedWorkItemSuccessMutationHandler = jest
    .fn()
    .mockResolvedValue(removeLinkedWorkItemResponse('Successfully unlinked IDs: 2.'));
  const removeLinkedWorkItemErrorMutationHandler = jest
    .fn()
    .mockResolvedValue(removeLinkedWorkItemResponse(null, ['Linked item removal failed']));
  const $toast = {
    show: jest.fn(),
  };

  const createComponent = async ({
    workItemQueryHandler = emptyLinkedWorkItemsQueryHandler,
    workItemType = 'Task',
    isGroup = false,
    removeLinkedWorkItemMutationHandler = removeLinkedWorkItemSuccessMutationHandler,
  } = {}) => {
    const mockApollo = createMockApollo([
      [workItemByIidQuery, workItemQueryHandler],
      [removeLinkedItemsMutation, removeLinkedWorkItemMutationHandler],
    ]);

    wrapper = shallowMountExtended(WorkItemRelationships, {
      apolloProvider: mockApollo,
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/1',
        workItemIid: '1',
        workItemFullPath: 'test-project-path',
        workItemType,
      },
      provide: {
        isGroup,
      },
      mocks: {
        $toast,
      },
    });

    await waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWidgetWrapper = () => wrapper.findComponent(WidgetWrapper);
  const findEmptyRelatedMessageContainer = () => wrapper.findByTestId('links-empty');
  const findLinkedItemsCountContainer = () => wrapper.findByTestId('linked-items-count');
  const findLinkedItemsHelpLink = () => wrapper.findByTestId('help-link');
  const findAllWorkItemRelationshipListComponents = () =>
    wrapper.findAllComponents(WorkItemRelationshipList);
  const findAddButton = () => wrapper.findByTestId('link-item-add-button');
  const findWorkItemRelationshipForm = () => wrapper.findComponent(WorkItemAddRelationshipForm);
  const findShowLabelsToggle = () => wrapper.findComponent(GlToggle);

  it('shows loading icon when query is not processed', () => {
    createComponent();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders the component with with defaults', async () => {
    await createComponent();

    expect(wrapper.find('.work-item-relationships').exists()).toBe(true);
    expect(findEmptyRelatedMessageContainer().exists()).toBe(true);
    expect(findAddButton().exists()).toBe(true);
    expect(findWorkItemRelationshipForm().exists()).toBe(false);
    expect(findLinkedItemsHelpLink().attributes('href')).toBe(
      '/help/user/okrs.md#linked-items-in-okrs',
    );
    expect(findShowLabelsToggle().props()).toMatchObject({
      value: true,
      labelPosition: 'left',
      label: 'Show labels',
    });
  });

  it('renders blocking linked item lists', async () => {
    await createComponent({
      workItemQueryHandler: jest
        .fn()
        .mockResolvedValue(workItemByIidResponseFactory({ linkedItems: mockBlockingLinkedItem })),
    });

    expect(findAllWorkItemRelationshipListComponents().length).toBe(1);
    expect(findLinkedItemsCountContainer().text()).toBe('1');
  });

  it('renders blocking, blocked by and related to linked item lists with proper count', async () => {
    await createComponent({
      workItemQueryHandler: jest
        .fn()
        .mockResolvedValue(workItemByIidResponseFactory({ linkedItems: mockLinkedItems })),
    });

    // renders all 3 lists: blocking, blocked by and related to
    expect(findAllWorkItemRelationshipListComponents().length).toBe(3);
    expect(findLinkedItemsCountContainer().text()).toBe('3');
  });

  it('shows an alert when list loading fails', async () => {
    const errorMessage = 'Some error';
    await createComponent({
      workItemQueryHandler: jest.fn().mockRejectedValue(new Error(errorMessage)),
    });

    expect(findWidgetWrapper().props('error')).toBe(errorMessage);
  });

  it('does not render add button when there is no permission', async () => {
    await createComponent({
      workItemQueryHandler: jest
        .fn()
        .mockResolvedValue(workItemByIidResponseFactory({ canAdminWorkItemLink: false })),
    });

    expect(findAddButton().exists()).toBe(false);
  });

  it('shows form on add button and hides when cancel button is clicked', async () => {
    await createComponent();

    await findAddButton().vm.$emit('click');
    expect(findWorkItemRelationshipForm().exists()).toBe(true);

    await findWorkItemRelationshipForm().vm.$emit('cancel');
    expect(findWorkItemRelationshipForm().exists()).toBe(false);
  });

  it.each`
    toggleValue
    ${true}
    ${false}
  `(
    'passes showLabels as $toggleValue to child items when toggle is $toggleValue',
    async ({ toggleValue }) => {
      await createComponent({
        workItemQueryHandler: jest
          .fn()
          .mockResolvedValue(workItemByIidResponseFactory({ linkedItems: mockLinkedItems })),
      });

      findShowLabelsToggle().vm.$emit('change', toggleValue);

      await nextTick();

      expect(findAllWorkItemRelationshipListComponents().at(0).props('showLabels')).toBe(
        toggleValue,
      );
    },
  );

  it('calls the work item query', () => {
    createComponent();

    expect(emptyLinkedWorkItemsQueryHandler).toHaveBeenCalled();
  });

  it('removes linked item and shows toast message when removeLinkedItem event is emitted', async () => {
    await createComponent({
      workItemQueryHandler: jest
        .fn()
        .mockResolvedValue(workItemByIidResponseFactory({ linkedItems: mockLinkedItems })),
    });

    expect(findLinkedItemsCountContainer().text()).toBe('3');

    await findAllWorkItemRelationshipListComponents()
      .at(0)
      .vm.$emit('removeLinkedItem', { id: 'gid://gitlab/WorkItem/2' });

    await waitForPromises();

    expect(removeLinkedWorkItemSuccessMutationHandler).toHaveBeenCalledWith({
      input: {
        id: 'gid://gitlab/WorkItem/1',
        workItemsIds: ['gid://gitlab/WorkItem/2'],
      },
    });

    expect($toast.show).toHaveBeenCalledWith('Linked item removed');

    expect(findLinkedItemsCountContainer().text()).toBe('2');
  });

  it.each`
    errorType                              | mutationMock                                               | errorMessage
    ${'an error in the mutation response'} | ${removeLinkedWorkItemErrorMutationHandler}                | ${'Linked item removal failed'}
    ${'a network error'}                   | ${jest.fn().mockRejectedValue(new Error('Network Error'))} | ${'Something went wrong when removing item. Please refresh this page.'}
  `(
    'shows an error message when there is $errorType while removing items',
    async ({ mutationMock, errorMessage }) => {
      await createComponent({
        workItemQueryHandler: jest
          .fn()
          .mockResolvedValue(workItemByIidResponseFactory({ linkedItems: mockLinkedItems })),
        removeLinkedWorkItemMutationHandler: mutationMock,
      });

      await findAllWorkItemRelationshipListComponents()
        .at(0)
        .vm.$emit('removeLinkedItem', { id: 'gid://gitlab/WorkItem/2' });

      await waitForPromises();

      expect(findWidgetWrapper().props('error')).toBe(errorMessage);
    },
  );
});
