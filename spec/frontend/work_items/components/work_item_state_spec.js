import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ItemState from '~/work_items/components/item_state.vue';
import WorkItemState from '~/work_items/components/work_item_state.vue';
import {
  i18n,
  STATE_OPEN,
  STATE_CLOSED,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse, workItemQueryResponse } from '../mock_data';

describe('WorkItemState component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findItemState = () => wrapper.findComponent(ItemState);

  const createComponent = ({
    state = STATE_OPEN,
    loading = false,
    mutationHandler = mutationSuccessHandler,
  } = {}) => {
    const { id, workItemType } = workItemQueryResponse.data.workItem;
    wrapper = shallowMount(WorkItemState, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        loading,
        workItem: {
          id,
          state,
          workItemType,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render state', () => {
      expect(findItemState().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent({ loading: false });
    });

    it('does not render loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders state', () => {
      expect(findItemState().props('state')).toBe(workItemQueryResponse.data.workItem.state);
    });
  });

  describe('when updating the state', () => {
    it('calls a mutation', () => {
      createComponent();

      findItemState().vm.$emit('changed', STATE_CLOSED);

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: workItemQueryResponse.data.workItem.id,
          stateEvent: STATE_EVENT_CLOSE,
        },
      });
    });

    it('calls a mutation with REOPEN', () => {
      createComponent({
        state: STATE_CLOSED,
      });

      findItemState().vm.$emit('changed', STATE_OPEN);

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: workItemQueryResponse.data.workItem.id,
          stateEvent: STATE_EVENT_REOPEN,
        },
      });
    });

    it('emits an error message when the mutation was unsuccessful', async () => {
      createComponent({ mutationHandler: jest.fn().mockRejectedValue('Error!') });

      findItemState().vm.$emit('changed', STATE_CLOSED);
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[i18n.updateError]]);
    });

    it('tracks editing the state', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      createComponent();

      findItemState().vm.$emit('changed', STATE_CLOSED);
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith('workItems:show', 'updated_state', {
        category: 'workItems:show',
        label: 'item_state',
        property: 'type_Task',
      });
    });
  });
});
