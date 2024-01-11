import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemStateToggle from '~/work_items/components/work_item_state_toggle.vue';
import {
  STATE_OPEN,
  STATE_CLOSED,
  STATE_EVENT_CLOSE,
  STATE_EVENT_REOPEN,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse, workItemQueryResponse } from '../mock_data';

describe('Work Item State toggle button component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const findStateToggleButton = () => wrapper.findComponent(GlButton);

  const { id } = workItemQueryResponse.data.workItem;

  const createComponent = ({
    mutationHandler = mutationSuccessHandler,
    canUpdate = true,
    workItemState = STATE_OPEN,
    workItemType = 'Task',
    hasComment = false,
  } = {}) => {
    wrapper = shallowMount(WorkItemStateToggle, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        workItemId: id,
        workItemState,
        workItemType,
        canUpdate,
        hasComment,
      },
    });
  };

  describe('work item State button text', () => {
    it.each`
      workItemState   | workItemType    | buttonText
      ${STATE_OPEN}   | ${'Task'}       | ${'Close task'}
      ${STATE_CLOSED} | ${'Task'}       | ${'Reopen task'}
      ${STATE_OPEN}   | ${'Objective'}  | ${'Close objective'}
      ${STATE_CLOSED} | ${'Objective'}  | ${'Reopen objective'}
      ${STATE_OPEN}   | ${'Key result'} | ${'Close key result'}
      ${STATE_CLOSED} | ${'Key result'} | ${'Reopen key result'}
    `(
      'is "$buttonText" when "$workItemType" state is "$workItemState"',
      ({ workItemState, workItemType, buttonText }) => {
        createComponent({ workItemState, workItemType });

        expect(findStateToggleButton().text()).toBe(buttonText);
      },
    );

    it.each`
      workItemState   | workItemType    | buttonText
      ${STATE_OPEN}   | ${'Task'}       | ${'Comment & close task'}
      ${STATE_CLOSED} | ${'Task'}       | ${'Comment & reopen task'}
      ${STATE_OPEN}   | ${'Objective'}  | ${'Comment & close objective'}
      ${STATE_CLOSED} | ${'Objective'}  | ${'Comment & reopen objective'}
      ${STATE_OPEN}   | ${'Key result'} | ${'Comment & close key result'}
      ${STATE_CLOSED} | ${'Key result'} | ${'Comment & reopen key result'}
    `(
      'is "$buttonText" when "$workItemType" state is "$workItemState" and hasComment is true',
      ({ workItemState, workItemType, buttonText }) => {
        createComponent({ workItemState, workItemType, hasComment: true });

        expect(findStateToggleButton().text()).toBe(buttonText);
      },
    );
  });

  describe('when updating the state', () => {
    it('calls a mutation', () => {
      createComponent();

      findStateToggleButton().vm.$emit('click');

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: workItemQueryResponse.data.workItem.id,
          stateEvent: STATE_EVENT_CLOSE,
        },
      });
    });

    it('calls a mutation with REOPEN', () => {
      createComponent({
        workItemState: STATE_CLOSED,
      });

      findStateToggleButton().vm.$emit('click');

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: workItemQueryResponse.data.workItem.id,
          stateEvent: STATE_EVENT_REOPEN,
        },
      });
    });

    it('emits `submit-comment` when hasComment is true', async () => {
      createComponent({ hasComment: true });

      findStateToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('submit-comment')).toBeDefined();
    });

    it('emits an error message when the mutation was unsuccessful', async () => {
      createComponent({ mutationHandler: jest.fn().mockRejectedValue('Error!') });

      findStateToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('tracks editing the state', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      createComponent();

      findStateToggleButton().vm.$emit('click');
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_state', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_state',
        property: 'type_Task',
      });
    });
  });
});
