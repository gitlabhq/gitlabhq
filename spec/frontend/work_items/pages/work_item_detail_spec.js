import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemState from '~/work_items/components/work_item_state.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import { i18n } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import { temporaryConfig } from '~/work_items/graphql/provider';
import { workItemTitleSubscriptionResponse, workItemQueryResponse } from '../mock_data';

describe('WorkItemDetail component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const initialSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);
  const findWorkItemState = () => wrapper.findComponent(WorkItemState);
  const findWorkItemDescription = () => wrapper.findComponent(WorkItemDescription);
  const findWorkItemAssignees = () => wrapper.findComponent(WorkItemAssignees);

  const createComponent = ({
    workItemId = workItemQueryResponse.data.workItem.id,
    handler = successHandler,
    subscriptionHandler = initialSubscriptionHandler,
    assigneesEnabled = false,
    includeAssigneesWidget = false,
  } = {}) => {
    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo(
        [
          [workItemQuery, handler],
          [workItemTitleSubscription, subscriptionHandler],
        ],
        {},
        {
          typePolicies: includeAssigneesWidget ? temporaryConfig.cacheConfig.typePolicies : {},
        },
      ),
      propsData: { workItemId },
      provide: {
        glFeatures: {
          workItemAssignees: assigneesEnabled,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when there is no `workItemId` prop', () => {
    beforeEach(() => {
      createComponent({ workItemId: null });
    });

    it('skips the work item query', () => {
      expect(successHandler).not.toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders skeleton loader', () => {
      expect(findSkeleton().exists()).toBe(true);
      expect(findWorkItemState().exists()).toBe(false);
      expect(findWorkItemTitle().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('does not render skeleton', () => {
      expect(findSkeleton().exists()).toBe(false);
      expect(findWorkItemState().exists()).toBe(true);
      expect(findWorkItemTitle().exists()).toBe(true);
    });
  });

  describe('description', () => {
    it('does not show description widget if loading description fails', () => {
      createComponent();

      expect(findWorkItemDescription().exists()).toBe(false);
    });

    it('shows description widget if description loads', async () => {
      createComponent();

      await waitForPromises();

      expect(findWorkItemDescription().exists()).toBe(true);
    });
  });

  it('shows an error message when the work item query was unsuccessful', async () => {
    const errorHandler = jest.fn().mockRejectedValue('Oops');
    createComponent({ handler: errorHandler });
    await waitForPromises();

    expect(errorHandler).toHaveBeenCalled();
    expect(findAlert().text()).toBe(i18n.fetchError);
  });

  it('shows an error message when WorkItemTitle emits an `error` event', async () => {
    createComponent();
    await waitForPromises();

    findWorkItemTitle().vm.$emit('error', i18n.updateError);
    await waitForPromises();

    expect(findAlert().text()).toBe(i18n.updateError);
  });

  it('calls the subscription', () => {
    createComponent();

    expect(initialSubscriptionHandler).toHaveBeenCalledWith({
      issuableId: workItemQueryResponse.data.workItem.id,
    });
  });

  it('emits workItemUpdated event when fields updated', async () => {
    createComponent();

    await waitForPromises();

    findWorkItemState().vm.$emit('updated');

    expect(wrapper.emitted('workItemUpdated')).toEqual([[]]);

    findWorkItemTitle().vm.$emit('updated');

    expect(wrapper.emitted('workItemUpdated')).toEqual([[], []]);
  });

  describe('when assignees feature flag is enabled', () => {
    it('renders assignees component when assignees widget is returned from the API', async () => {
      createComponent({
        assigneesEnabled: true,
        includeAssigneesWidget: true,
      });
      await waitForPromises();

      expect(findWorkItemAssignees().exists()).toBe(true);
    });

    it('does not render assignees component when assignees widget is not returned from the API', async () => {
      createComponent({
        assigneesEnabled: true,
        includeAssigneesWidget: false,
      });
      await waitForPromises();

      expect(findWorkItemAssignees().exists()).toBe(false);
    });
  });

  it('does not render assignees component when assignees feature flag is disabled', async () => {
    createComponent();
    await waitForPromises();

    expect(findWorkItemAssignees().exists()).toBe(false);
  });
});
