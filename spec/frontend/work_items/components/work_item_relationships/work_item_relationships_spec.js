import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';

import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';
import WorkItemRelationships from '~/work_items/components/work_item_relationships/work_item_relationships.vue';
import WorkItemRelationshipList from '~/work_items/components/work_item_relationships/work_item_relationship_list.vue';
import WorkItemAddRelationshipForm from '~/work_items/components/work_item_relationships/work_item_add_relationship_form.vue';
import groupWorkItemByIidQuery from '~/work_items/graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import {
  groupWorkItemByIidResponseFactory,
  workItemByIidResponseFactory,
  mockLinkedItems,
  mockBlockingLinkedItem,
} from '../../mock_data';

describe('WorkItemRelationships', () => {
  Vue.use(VueApollo);

  let wrapper;
  const emptyLinkedWorkItemsQueryHandler = jest
    .fn()
    .mockResolvedValue(workItemByIidResponseFactory());
  const groupWorkItemsQueryHandler = jest
    .fn()
    .mockResolvedValue(groupWorkItemByIidResponseFactory());

  const createComponent = async ({
    workItemQueryHandler = emptyLinkedWorkItemsQueryHandler,
    workItemType = 'Task',
    isGroup = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemRelationships, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemQueryHandler],
        [groupWorkItemByIidQuery, groupWorkItemsQueryHandler],
      ]),
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/1',
        workItemIid: '1',
        workItemFullPath: 'test-project-path',
        workItemType,
      },
      provide: {
        isGroup,
      },
    });

    await waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWidgetWrapper = () => wrapper.findComponent(WidgetWrapper);
  const findEmptyRelatedMessageContainer = () => wrapper.findByTestId('links-empty');
  const findLinkedItemsCountContainer = () => wrapper.findByTestId('linked-items-count');
  const findAllWorkItemRelationshipListComponents = () =>
    wrapper.findAllComponents(WorkItemRelationshipList);
  const findAddButton = () => wrapper.findByTestId('link-item-add-button');
  const findWorkItemRelationshipForm = () => wrapper.findComponent(WorkItemAddRelationshipForm);

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

  describe('when project context', () => {
    it('calls the project work item query', () => {
      createComponent();

      expect(emptyLinkedWorkItemsQueryHandler).toHaveBeenCalled();
    });

    it('skips calling the group work item query', () => {
      createComponent();

      expect(groupWorkItemsQueryHandler).not.toHaveBeenCalled();
    });
  });

  describe('when group context', () => {
    it('skips calling the project work item query', () => {
      createComponent({ isGroup: true });

      expect(emptyLinkedWorkItemsQueryHandler).not.toHaveBeenCalled();
    });

    it('calls the group work item query', () => {
      createComponent({ isGroup: true });

      expect(groupWorkItemsQueryHandler).toHaveBeenCalled();
    });
  });
});
