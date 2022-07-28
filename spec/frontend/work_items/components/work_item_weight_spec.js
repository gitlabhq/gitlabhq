import { GlForm, GlFormInput } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { __ } from '~/locale';
import WorkItemWeight from '~/work_items/components/work_item_weight.vue';
import { i18n, TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse } from 'jest/work_items/mock_data';

describe('WorkItemWeight component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Task';

  const findForm = () => wrapper.findComponent(GlForm);
  const findInput = () => wrapper.findComponent(GlFormInput);

  const createComponent = ({
    canUpdate = false,
    hasIssueWeightsFeature = true,
    isEditing = false,
    weight,
    mutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse),
  } = {}) => {
    wrapper = mountExtended(WorkItemWeight, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        canUpdate,
        weight,
        workItemId,
        workItemType,
      },
      provide: {
        hasIssueWeightsFeature,
      },
    });

    if (isEditing) {
      findInput().vm.$emit('focus');
    }
  };

  describe('`issue_weights` licensed feature', () => {
    describe.each`
      description             | hasIssueWeightsFeature | exists
      ${'when available'}     | ${true}                | ${true}
      ${'when not available'} | ${false}               | ${false}
    `('$description', ({ hasIssueWeightsFeature, exists }) => {
      it(hasIssueWeightsFeature ? 'renders component' : 'does not render component', () => {
        createComponent({ hasIssueWeightsFeature });

        expect(findForm().exists()).toBe(exists);
      });
    });
  });

  describe('weight input', () => {
    it('has "Weight" label', () => {
      createComponent();

      expect(wrapper.findByLabelText(__('Weight')).exists()).toBe(true);
    });

    describe('placeholder attribute', () => {
      describe.each`
        description                             | isEditing | canUpdate | value
        ${'when not editing and cannot update'} | ${false}  | ${false}  | ${__('None')}
        ${'when editing and cannot update'}     | ${true}   | ${false}  | ${__('None')}
        ${'when not editing and can update'}    | ${false}  | ${true}   | ${__('None')}
        ${'when editing and can update'}        | ${true}   | ${true}   | ${__('Enter a number')}
      `('$description', ({ isEditing, canUpdate, value }) => {
        it(`has a value of "${value}"`, async () => {
          createComponent({ canUpdate, isEditing });
          await nextTick();

          expect(findInput().attributes('placeholder')).toBe(value);
        });
      });
    });

    describe('readonly attribute', () => {
      describe.each`
        description             | canUpdate | value
        ${'when cannot update'} | ${false}  | ${'readonly'}
        ${'when can update'}    | ${true}   | ${undefined}
      `('$description', ({ canUpdate, value }) => {
        it(`renders readonly=${value}`, () => {
          createComponent({ canUpdate });

          expect(findInput().attributes('readonly')).toBe(value);
        });
      });
    });

    describe('type attribute', () => {
      describe.each`
        description                             | isEditing | canUpdate | type
        ${'when not editing and cannot update'} | ${false}  | ${false}  | ${'text'}
        ${'when editing and cannot update'}     | ${true}   | ${false}  | ${'text'}
        ${'when not editing and can update'}    | ${false}  | ${true}   | ${'text'}
        ${'when editing and can update'}        | ${true}   | ${true}   | ${'number'}
      `('$description', ({ isEditing, canUpdate, type }) => {
        it(`has a value of "${type}"`, async () => {
          createComponent({ canUpdate, isEditing });
          await nextTick();

          expect(findInput().attributes('type')).toBe(type);
        });
      });
    });

    describe('value attribute', () => {
      describe.each`
        weight       | value
        ${1}         | ${'1'}
        ${0}         | ${'0'}
        ${null}      | ${''}
        ${undefined} | ${''}
      `('when `weight` prop is "$weight"', ({ weight, value }) => {
        it(`value is "${value}"`, () => {
          createComponent({ weight });

          expect(findInput().element.value).toBe(value);
        });
      });
    });

    describe('when blurred', () => {
      it('calls a mutation to update the weight when the input value is different', () => {
        const mutationSpy = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
        createComponent({
          isEditing: true,
          weight: 0,
          mutationHandler: mutationSpy,
          canUpdate: true,
        });

        findInput().vm.$emit('blur', { target: { value: 1 } });

        expect(mutationSpy).toHaveBeenCalledWith({
          input: {
            id: workItemId,
            weightWidget: {
              weight: 1,
            },
          },
        });
      });

      it('does not call a mutation to update the weight when the input value is the same', () => {
        const mutationSpy = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);
        createComponent({ isEditing: true, mutationHandler: mutationSpy, canUpdate: true });

        findInput().trigger('blur');

        expect(mutationSpy).not.toHaveBeenCalledWith();
      });

      it('emits an error when there is a GraphQL error', async () => {
        const response = {
          data: {
            workItemUpdate: {
              errors: ['Error!'],
              workItem: {},
            },
          },
        };
        createComponent({
          isEditing: true,
          mutationHandler: jest.fn().mockResolvedValue(response),
          canUpdate: true,
        });

        findInput().trigger('blur');
        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[i18n.updateError]]);
      });

      it('emits an error when there is a network error', async () => {
        createComponent({
          isEditing: true,
          mutationHandler: jest.fn().mockRejectedValue(new Error()),
          canUpdate: true,
        });

        findInput().trigger('blur');
        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[i18n.updateError]]);
      });

      it('tracks updating the weight', () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        createComponent({ canUpdate: true });

        findInput().trigger('blur');

        expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_weight', {
          category: TRACKING_CATEGORY_SHOW,
          label: 'item_weight',
          property: 'type_Task',
        });
      });
    });
  });
});
