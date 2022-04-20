import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import { i18n } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import { workItemTitleSubscriptionResponse, workItemQueryResponse } from '../mock_data';

describe('WorkItemDetail component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const initialSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);

  const createComponent = ({
    workItemId = workItemQueryResponse.data.workItem.id,
    handler = successHandler,
    subscriptionHandler = initialSubscriptionHandler,
  } = {}) => {
    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo([
        [workItemQuery, handler],
        [workItemTitleSubscription, subscriptionHandler],
      ]),
      propsData: { workItemId },
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

    it('renders WorkItemTitle in loading state', () => {
      expect(findWorkItemTitle().props('loading')).toBe(true);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('does not render WorkItemTitle in loading state', () => {
      expect(findWorkItemTitle().props('loading')).toBe(false);
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
});
