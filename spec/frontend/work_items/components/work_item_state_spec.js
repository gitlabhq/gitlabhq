import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ItemState from '~/work_items/components/item_state.vue';
import WorkItemState from '~/work_items/components/work_item_state.vue';
import {
  STATE_OPEN,
  STATE_CLOSED,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse, workItemQueryResponse } from '../mock_data';

describe('WorkItemState component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const findItemState = () => wrapper.findComponent(ItemState);

  const createComponent = ({
    state = STATE_OPEN,
    mutationHandler = mutationSuccessHandler,
    canUpdate = true,
  } = {}) => {
    const { id, workItemType } = workItemQueryResponse.data.workItem;
    wrapper = shallowMount(WorkItemState, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        workItem: {
          id,
          state,
          workItemType,
        },
        canUpdate,
      },
    });
  };

  it('renders state', () => {
    createComponent();

    expect(findItemState().props('state')).toBe(workItemQueryResponse.data.workItem.state);
  });

  describe('item state disabled prop', () => {
    describe.each`
      description             | canUpdate | value
      ${'when cannot update'} | ${false}  | ${true}
      ${'when can update'}    | ${true}   | ${false}
    `('$description', ({ canUpdate, value }) => {
      it(`renders item state component with disabled=${value}`, () => {
        createComponent({ canUpdate });

        expect(findItemState().props('disabled')).toBe(value);
      });
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

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('tracks editing the state', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      createComponent();

      findItemState().vm.$emit('changed', STATE_CLOSED);
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_state', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_state',
        property: 'type_Task',
      });
    });
  });
});
