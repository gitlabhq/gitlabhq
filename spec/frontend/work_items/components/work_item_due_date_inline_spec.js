import { GlFormGroup, GlDatepicker } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemDueDate from '~/work_items/components/work_item_due_date_inline.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse, updateWorkItemMutationErrorResponse } from '../mock_data';

describe('WorkItemDueDate component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemId = 'gid://gitlab/WorkItem/1';
  const updateWorkItemMutationHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const findStartDateButton = () =>
    wrapper.findByRole('button', { name: WorkItemDueDate.i18n.addStartDate });
  const findStartDateInput = () => wrapper.findByLabelText(WorkItemDueDate.i18n.startDate);
  const findStartDatePicker = () => wrapper.findComponent(GlDatepicker);
  const findDueDateButton = () =>
    wrapper.findByRole('button', { name: WorkItemDueDate.i18n.addDueDate });
  const findDueDateInput = () => wrapper.findByLabelText(WorkItemDueDate.i18n.dueDate);
  const findDueDatePicker = () => wrapper.findAllComponents(GlDatepicker).at(1);
  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);

  const createComponent = ({
    canUpdate = false,
    dueDate = null,
    startDate = null,
    mutationHandler = updateWorkItemMutationHandler,
    stubs = {},
  } = {}) => {
    wrapper = mountExtended(WorkItemDueDate, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        canUpdate,
        dueDate,
        startDate,
        workItemId,
        workItemType: 'Task',
      },
      stubs,
    });
  };

  describe('when can update', () => {
    describe('start date', () => {
      describe('`Add start date` button', () => {
        describe.each`
          description                      | startDate       | exists
          ${'when there is no start date'} | ${null}         | ${true}
          ${'when there is a start date'}  | ${'2022-01-01'} | ${false}
        `('$description', ({ startDate, exists }) => {
          beforeEach(() => {
            createComponent({ canUpdate: true, startDate });
          });

          it(`${exists ? 'renders' : 'does not render'}`, () => {
            expect(findStartDateButton().exists()).toBe(exists);
          });
        });

        describe('when it emits `click` event', () => {
          beforeEach(() => {
            createComponent({ canUpdate: true, startDate: null });
            findStartDateButton().vm.$emit('click');
          });

          it('renders start date picker', () => {
            expect(findStartDateInput().exists()).toBe(true);
          });

          it('hides itself', () => {
            expect(findStartDateButton().exists()).toBe(false);
          });
        });
      });

      describe('date picker', () => {
        describe('when it emits a `clear` event', () => {
          beforeEach(() => {
            createComponent({ canUpdate: true, dueDate: '2022-01-01', startDate: '2022-01-01' });
            findStartDatePicker().vm.$emit('clear');
          });

          it('hides the date picker', () => {
            expect(findStartDateInput().exists()).toBe(false);
          });

          it('shows the `Add start date` button', () => {
            expect(findStartDateButton().exists()).toBe(true);
          });

          it('calls a mutation to update the dates', () => {
            expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
              input: {
                id: workItemId,
                startAndDueDateWidget: {
                  dueDate: new Date('2022-01-01T00:00:00.000Z'),
                  startDate: null,
                },
              },
            });
          });
        });

        describe('when it emits a `close` event', () => {
          describe('when the start date is earlier than the due date', () => {
            const startDate = new Date('2022-01-01T00:00:00.000Z');

            beforeEach(() => {
              createComponent({ canUpdate: true, dueDate: '2022-12-31', startDate: '2022-12-31' });
              findStartDatePicker().vm.$emit('input', startDate);
              findStartDatePicker().vm.$emit('close');
            });

            it('calls a mutation to update the dates', () => {
              expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
                input: {
                  id: workItemId,
                  startAndDueDateWidget: {
                    dueDate: new Date('2022-12-31T00:00:00.000Z'),
                    startDate,
                  },
                },
              });
            });
          });

          describe('when the start date is later than the due date', () => {
            const startDate = new Date('2030-01-01T00:00:00.000Z');
            const datePickerOpenSpy = jest.fn();

            beforeEach(() => {
              createComponent({
                canUpdate: true,
                dueDate: '2022-12-31',
                startDate: '2022-12-31',
                stubs: {
                  GlDatepicker: stubComponent(GlDatepicker, {
                    methods: {
                      show: datePickerOpenSpy,
                    },
                  }),
                },
              });
              findStartDatePicker().vm.$emit('input', startDate);
              findStartDatePicker().vm.$emit('close');
            });

            it('does not call a mutation to update the dates', () => {
              expect(updateWorkItemMutationHandler).not.toHaveBeenCalled();
            });

            it('updates the due date picker to the same date', () => {
              expect(findDueDatePicker().props('value')).toEqual(startDate);
            });

            it('opens the due date picker', () => {
              expect(datePickerOpenSpy).toHaveBeenCalled();
            });
          });
        });
      });
    });

    describe('due date', () => {
      describe('`Add due date` button', () => {
        describe.each`
          description                    | dueDate         | exists
          ${'when there is no due date'} | ${null}         | ${true}
          ${'when there is a due date'}  | ${'2022-01-01'} | ${false}
        `('$description', ({ dueDate, exists }) => {
          beforeEach(() => {
            createComponent({ canUpdate: true, dueDate });
          });

          it(`${exists ? 'renders' : 'does not render'}`, () => {
            expect(findDueDateButton().exists()).toBe(exists);
          });
        });

        describe('when it emits `click` event', () => {
          beforeEach(() => {
            createComponent({ canUpdate: true, dueDate: null });
            findDueDateButton().vm.$emit('click');
          });

          it('renders due date picker', () => {
            expect(findDueDateInput().exists()).toBe(true);
          });

          it('hides itself', () => {
            expect(findDueDateButton().exists()).toBe(false);
          });
        });
      });

      describe('date picker', () => {
        describe('when it emits a `clear` event', () => {
          beforeEach(() => {
            createComponent({ canUpdate: true, dueDate: '2022-01-01', startDate: '2022-01-01' });
            findDueDatePicker().vm.$emit('clear');
          });

          it('hides the date picker', () => {
            expect(findDueDateInput().exists()).toBe(false);
          });

          it('shows the `Add due date` button', () => {
            expect(findDueDateButton().exists()).toBe(true);
          });

          it('calls a mutation to update the dates', () => {
            expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
              input: {
                id: workItemId,
                startAndDueDateWidget: {
                  dueDate: null,
                  startDate: new Date('2022-01-01T00:00:00.000Z'),
                },
              },
            });
          });
        });

        describe('when it emits a `close` event', () => {
          const dueDate = new Date('2022-12-31T00:00:00.000Z');

          beforeEach(() => {
            createComponent({ canUpdate: true, dueDate: '2022-01-01', startDate: '2022-01-01' });
            findDueDatePicker().vm.$emit('input', dueDate);
            findDueDatePicker().vm.$emit('close');
          });

          it('calls a mutation to update the dates', () => {
            expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
              input: {
                id: workItemId,
                startAndDueDateWidget: {
                  dueDate,
                  startDate: new Date('2022-01-01T00:00:00.000Z'),
                },
              },
            });
          });
        });
      });
    });

    describe('when updating date', () => {
      describe('when dates are changed', () => {
        let trackingSpy;

        beforeEach(() => {
          createComponent({ canUpdate: true, dueDate: '2022-12-31', startDate: '2022-12-31' });
          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

          findStartDatePicker().vm.$emit('input', new Date('2022-01-01T00:00:00.000Z'));
          findStartDatePicker().vm.$emit('close');
        });

        it('mutation is called to update dates', () => {
          expect(updateWorkItemMutationHandler).toHaveBeenCalledWith({
            input: {
              id: workItemId,
              startAndDueDateWidget: {
                dueDate: new Date('2022-12-31T00:00:00.000Z'),
                startDate: new Date('2022-01-01T00:00:00.000Z'),
              },
            },
          });
        });

        it('start date input is disabled', () => {
          expect(findStartDatePicker().props('disabled')).toBe(true);
        });

        it('due date input is disabled', () => {
          expect(findDueDatePicker().props('disabled')).toBe(true);
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
        beforeEach(() => {
          createComponent({ canUpdate: true, dueDate: '2022-12-31', startDate: '2022-12-31' });

          findStartDatePicker().vm.$emit('input', new Date('2022-12-31T00:00:00.000Z'));
          findStartDatePicker().vm.$emit('close');
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
        beforeEach(() => {
          createComponent({
            canUpdate: true,
            dueDate: '2022-12-31',
            startDate: '2022-12-31',
            mutationHandler,
          });

          findStartDatePicker().vm.$emit('input', new Date('2022-01-01T00:00:00.000Z'));
          findStartDatePicker().vm.$emit('close');
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

  describe('when cannot update', () => {
    it('start and due date inputs are disabled', async () => {
      createComponent({ canUpdate: false, dueDate: '2022-01-01', startDate: '2022-01-01' });
      await nextTick();

      expect(findStartDateInput().props('disabled')).toBe(true);
      expect(findDueDateInput().props('disabled')).toBe(true);
    });

    describe('when there is no start and due date', () => {
      it('shows None', () => {
        createComponent({ canUpdate: false, dueDate: null, startDate: null });

        expect(findGlFormGroup().text()).toContain(WorkItemDueDate.i18n.none);
      });
    });
  });
});
