import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlFormInput, GlFormFields, GlFormDate } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { TODO_STATE_PENDING } from '~/todos/constants';
import { useFakeDate } from 'helpers/fake_date';
import SnoozeTodoModal from '~/todos/components/snooze_todo_modal.vue';
import { stubComponent } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'jest/__helpers__/tracking_helper';

Vue.use(VueApollo);

describe('SnoozeTodoModal', () => {
  let wrapper;
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
  };
  const mockCurrentTime = new Date('2024-12-18T13:24:00');

  useFakeDate(mockCurrentTime);

  const findTimeInput = () => wrapper.findByTestId('time-input');
  const findDateInput = () => wrapper.findByTestId('date-input');
  const findDatetimeInPastError = () => wrapper.findByTestId('datetime-in-past-error');

  const setTime = (time) => {
    findTimeInput().findComponent(GlFormInput).vm.$emit('input', time);
    findTimeInput().findComponent(GlFormInput).vm.$emit('blur');
    return nextTick();
  };
  const setDate = (date) => {
    findDateInput().findComponent(GlFormInput).vm.$emit('change', date);
    findDateInput().findComponent(GlFormInput).vm.$emit('blur');
    return nextTick();
  };
  const submitForm = () => {
    wrapper.findComponent(GlFormFields).vm.$emit('submit');
    return nextTick();
  };

  const createComponent = ({ mountFn = shallowMountExtended, props = {} } = {}) => {
    wrapper = mountFn(SnoozeTodoModal, {
      propsData: {
        todo: mockTodo,
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: '<div><slot /></div>',
        }),
        GlFormFields,
        GlFormDate,
      },
    });
  };

  it('renders the time and date inputs', () => {
    createComponent({ mountFn: mountExtended });

    expect(findTimeInput().exists()).toBe(true);
    expect(findDateInput().exists()).toBe(true);
  });

  it('the time input defaults to 9:00AM', () => {
    createComponent({ mountFn: mountExtended });

    expect(findTimeInput().findComponent(GlFormInput).vm.$el.value).toBe('09:00');
  });

  it('shows an error message if the selected date and time are in the past', async () => {
    createComponent({ mountFn: mountExtended });
    await setTime('13:24');
    await setDate('2024-12-18');

    expect(findDatetimeInPastError().exists()).toBe(false);

    await setTime('13:23');

    expect(findDatetimeInPastError().exists()).toBe(true);
    expect(findDatetimeInPastError().text()).toBe(
      'The selected date and time cannot be in the past.',
    );
  });

  describe('form validators', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('shows an error message if no time is provided', async () => {
      expect(wrapper.findByText('The time is required.').exists()).toBe(false);

      await setTime('');

      expect(wrapper.findByText('The time is required.').exists()).toBe(true);
    });

    it('shows an error message if no date is provided', async () => {
      expect(wrapper.findByText('The date is required.').exists()).toBe(false);

      await setDate('');

      expect(wrapper.findByText('The date is required.').exists()).toBe(true);
    });

    it('shows an error message if the selected datetime is in the past', async () => {
      await setTime('15:00');
      await setDate('2024-12-01');

      expect(wrapper.findByText("Snooze date can't be in the past.").exists()).toBe(true);

      await setDate('2025-01-01');

      expect(wrapper.findByText("Snooze date can't be in the past.").exists()).toBe(false);
    });
  });

  it('triggers the snooze mutation and tracks an event when submitting the form', async () => {
    createComponent({ mountFn: mountExtended });
    const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    const time = '15:00';
    const date = '2025-01-01';
    const expectedTimestamp = `${date}T${time}:00.000Z`;
    await setTime(time);
    await setDate(date);
    submitForm();

    expect(wrapper.emitted().submit[0]).toEqual([new Date(expectedTimestamp)]);
    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_todo_item_action', {
      label: 'snooze_until_a_specific_date_and_time',
      extra: {
        snooze_until: expectedTimestamp,
      },
    });

    unmockTracking();
  });
});
