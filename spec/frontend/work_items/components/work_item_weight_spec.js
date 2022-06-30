import { GlForm, GlFormInput } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mockTracking } from 'helpers/tracking_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';
import WorkItemWeight from '~/work_items/components/work_item_weight.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import localUpdateWorkItemMutation from '~/work_items/graphql/local_update_work_item.mutation.graphql';

describe('WorkItemWeight component', () => {
  let wrapper;

  const mutateSpy = jest.fn();
  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Task';

  const findForm = () => wrapper.findComponent(GlForm);
  const findInput = () => wrapper.findComponent(GlFormInput);

  const createComponent = ({
    canUpdate = false,
    hasIssueWeightsFeature = true,
    isEditing = false,
    weight,
  } = {}) => {
    wrapper = mountExtended(WorkItemWeight, {
      propsData: {
        canUpdate,
        weight,
        workItemId,
        workItemType,
      },
      provide: {
        hasIssueWeightsFeature,
      },
      mocks: {
        $apollo: {
          mutate: mutateSpy,
        },
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
      it('calls a mutation to update the weight', () => {
        const weight = 0;
        createComponent({ isEditing: true, weight });

        findInput().trigger('blur');

        expect(mutateSpy).toHaveBeenCalledWith({
          mutation: localUpdateWorkItemMutation,
          variables: {
            input: {
              id: workItemId,
              weight,
            },
          },
        });
      });

      it('tracks updating the weight', () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        createComponent();

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
