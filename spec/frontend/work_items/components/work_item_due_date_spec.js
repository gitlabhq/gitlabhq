import { GlDatepicker } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { Mousetrap } from '~/lib/mousetrap';
import { newDate } from '~/lib/utils/datetime/date_calculation_utility';
import WorkItemDueDate from '~/work_items/components/work_item_due_date.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse, updateWorkItemMutationErrorResponse } from '../mock_data';

Vue.use(VueApollo);

describe('WorkItemDueDate component', () => {
  let wrapper;

  const startDateShowSpy = jest.fn();

  const workItemId = 'gid://gitlab/WorkItem/1';
  const updateWorkItemMutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const findStartDatePicker = () => wrapper.findComponent({ ref: 'startDatePicker' });
  const findDueDatePicker = () => wrapper.findByTestId('due-date-picker');
  const findApplyButton = () => wrapper.findByTestId('apply-button');
  const findEditButton = () => wrapper.findByTestId('edit-button');
  const findDatepickerWrapper = () => wrapper.findByTestId('datepicker-wrapper');
  const findStartDateValue = () => wrapper.findByTestId('start-date-value');
  const findDueDateValue = () => wrapper.findByTestId('due-date-value');

  const createComponent = ({
    canUpdate = false,
    dueDate = null,
    startDate = null,
    mutationHandler = updateWorkItemMutationHandler,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemDueDate, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        canUpdate,
        dueDate,
        startDate,
        workItemType: 'Task',
        workItem: updateWorkItemMutationResponse.data.workItemUpdate.workItem,
      },
      stubs: {
        GlDatepicker: stubComponent(GlDatepicker, {
          methods: {
            show: startDateShowSpy,
          },
        }),
      },
    });
  };

  describe('when in default state', () => {
    describe('start date', () => {
      it('is rendered correctly when it is passed to the component', () => {
        createComponent({ startDate: '2022-01-01' });

        expect(findStartDateValue().text()).toBe('Jan 1, 2022');
        expect(findStartDateValue().classes('gl-text-subtle')).toBe(false);
      });

      it('renders `None` when it is  not passed to the component`', () => {
        createComponent();

        expect(findStartDateValue().text()).toBe('None');
        expect(findStartDateValue().classes('gl-text-subtle')).toBe(true);
      });
    });

    describe('end date', () => {
      it('is rendered correctly when it is passed to the component', () => {
        createComponent({ dueDate: '2022-01-01' });

        expect(findDueDateValue().text()).toContain('Jan 1, 2022');
        expect(findDueDateValue().classes('gl-text-subtle')).toBe(false);
      });

      it('renders `None` when it is  not passed to the component`', () => {
        createComponent();

        expect(findDueDateValue().text()).toContain('None');
        expect(findDueDateValue().classes('gl-text-subtle')).toBe(true);
      });
    });

    it('does not render datepickers', () => {
      createComponent();

      expect(findStartDatePicker().exists()).toBe(false);
      expect(findDueDatePicker().exists()).toBe(false);
    });

    it('does not render edit button when user cannot update work item', () => {
      createComponent();

      expect(findEditButton().exists()).toBe(false);
    });

    it('renders edit button when user can update work item', () => {
      createComponent({ canUpdate: true });

      expect(findEditButton().exists()).toBe(true);
    });

    it('expands the widget when edit button is clicked', async () => {
      createComponent({ canUpdate: true });
      findEditButton().vm.$emit('click');
      await nextTick();

      expect(findDatepickerWrapper().exists()).toBe(true);
      expect(findStartDateValue().exists()).toBe(false);
      expect(findDueDateValue().exists()).toBe(false);
    });
  });

  describe('when in editing state', () => {
    it('collapses the widget when apply button is clicked', async () => {
      createComponent({ canUpdate: true });
      findEditButton().vm.$emit('click');
      await nextTick();

      findApplyButton().vm.$emit('click');
      await nextTick();

      expect(findDatepickerWrapper().exists()).toBe(false);
    });

    it('updates datepicker props when component startDate and dueDate props are updated', async () => {
      createComponent({ canUpdate: true });
      findEditButton().vm.$emit('click');
      await nextTick();

      expect(findStartDatePicker().props('value')).toBe(null);
      expect(findDueDatePicker().props('value')).toBe(null);

      await wrapper.setProps({
        startDate: '2022-01-01',
        dueDate: '2022-01-02',
      });

      expect(findStartDatePicker().props('value')).toEqual(newDate('2022-01-01'));
      expect(findDueDatePicker().props('value')).toEqual(newDate('2022-01-02'));
    });

    describe('start date picker', () => {
      beforeEach(() => {
        createComponent({
          canUpdate: true,
          dueDate: '2022-01-02',
          startDate: '2022-01-02',
        });

        findEditButton().vm.$emit('click');
        return nextTick();
      });

      it('clears the start date input on `clear` event', async () => {
        findStartDatePicker().vm.$emit('clear');
        await nextTick();

        expect(findStartDatePicker().props('value')).toBe(null);
      });

      describe('when the start date is later than the due date', () => {
        const startDate = new Date('2030-01-01T00:00:00.000Z');

        it('updates the due date picker to the same date', async () => {
          findStartDatePicker().vm.$emit('input', startDate);
          findStartDatePicker().vm.$emit('close');
          await nextTick();

          expect(findDueDatePicker().props('value')).toEqual(startDate);
        });
      });
    });

    describe('when escape key is pressed', () => {
      beforeEach(async () => {
        createComponent({
          canUpdate: true,
          dueDate: '2022-12-31',
          startDate: '2022-12-31',
        });

        findEditButton().vm.$emit('click');
        await nextTick();

        findStartDatePicker().vm.$emit('input', new Date('2022-01-01T00:00:00.000Z'));
      });

      it('widget is closed and dates are updated, when date picker is focused', async () => {
        findStartDatePicker().trigger('keydown.esc');
        await nextTick();

        expect(updateWorkItemMutationHandler).toHaveBeenCalled();
        expect(findStartDatePicker().exists()).toBe(false);
      });

      it('widget is closed and dates are updated, when date picker is not focused', async () => {
        findStartDatePicker().trigger('blur');
        Mousetrap.trigger('esc');
        await nextTick();

        expect(updateWorkItemMutationHandler).toHaveBeenCalled();
        expect(findStartDatePicker().exists()).toBe(false);
      });
    });

    describe('when updating date', () => {
      describe('when dates are changed', () => {
        let trackingSpy;

        beforeEach(async () => {
          createComponent({
            canUpdate: true,
            dueDate: '2022-12-31',
            startDate: '2022-12-31',
          });
          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

          findEditButton().vm.$emit('click');
          await nextTick();

          findStartDatePicker().vm.$emit('input', new Date('2022-01-01T00:00:00.000Z'));
          findStartDatePicker().vm.$emit('close');

          await nextTick();
          findApplyButton().vm.$emit('click');
        });

        it('mutation is called to update dates', () => {
          expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
            input: {
              id: workItemId,
              startAndDueDateWidget: {
                dueDate: '2022-12-31',
                startDate: '2022-01-01',
              },
            },
          });
        });

        it('edit button is disabled when mutation is in flight', () => {
          expect(findEditButton().props('disabled')).toBe(true);
        });

        it('edit button is enabled after mutation is resolved', async () => {
          await waitForPromises();
          expect(findEditButton().props('disabled')).toBe(false);
        });

        it('tracks updating the dates', () => {
          expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_dates', {
            category: TRACKING_CATEGORY_SHOW,
            label: 'item_dates',
            property: 'type_Task',
          });
        });
      });

      describe('when dates are unchanged', () => {
        beforeEach(async () => {
          createComponent({
            canUpdate: true,
            dueDate: '2022-12-31',
            startDate: '2022-12-31',
          });

          findEditButton().vm.$emit('click');
          await nextTick();

          findStartDatePicker().vm.$emit('input', new Date('2022-12-31T00:00:00.000Z'));
          findStartDatePicker().vm.$emit('close');

          await nextTick();
          findApplyButton().vm.$emit('click');
        });

        it('mutation is not called to update dates', () => {
          expect(updateWorkItemMutationHandler).not.toHaveBeenCalled();
        });
      });

      describe.each`
        description                        | mutationHandler
        ${'when there is a GraphQL error'} | ${jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse)}
        ${'when there is a network error'} | ${jest.fn().mockRejectedValue(new Error())}
      `('$description', ({ mutationHandler }) => {
        beforeEach(async () => {
          createComponent({
            canUpdate: true,
            dueDate: '2022-12-31',
            startDate: '2022-12-31',
            mutationHandler,
          });

          findEditButton().vm.$emit('click');
          await nextTick();

          findStartDatePicker().vm.$emit('input', new Date('2022-01-01T00:00:00.000Z'));
          findStartDatePicker().vm.$emit('close');

          await nextTick();
          findApplyButton().vm.$emit('click');
          return waitForPromises();
        });

        it('emits an error', () => {
          expect(wrapper.emitted('error')).toEqual([
            ['Something went wrong while updating the task. Please try again.'],
          ]);
        });
      });
    });
  });
});
