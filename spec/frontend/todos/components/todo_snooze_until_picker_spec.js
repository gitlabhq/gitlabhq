import { GlTooltip } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import { stubComponent } from 'helpers/stub_component';
import { mockTracking, unmockTracking } from 'jest/__helpers__/tracking_helper';
import SnoozeTimePicker from '~/todos/components/todo_snooze_until_picker.vue';
import SnoozeTodoModal from '~/todos/components/snooze_todo_modal.vue';

describe('SnoozeTimePicker', () => {
  let wrapper;
  const mockCurrentTime = new Date('2024-12-18T13:24:00');
  const SnoozeTodoModalStub = stubComponent(SnoozeTodoModal, {
    methods: {
      show: jest.fn(),
    },
  });

  useFakeDate(mockCurrentTime);

  const findGlTooltip = () => wrapper.findComponent(GlTooltip);
  const findSnoozeDropdown = () => wrapper.findByTestId('snooze-dropdown');
  const getPredefinedSnoozingOption = (index) =>
    findSnoozeDropdown().props('items')[0].items[index];

  const createComponent = () => {
    wrapper = shallowMountExtended(SnoozeTimePicker, {
      provide: {
        currentTime: mockCurrentTime,
      },
      stubs: {
        SnoozeTodoModal: SnoozeTodoModalStub,
      },
    });
  };

  it('renders the snoozing options', () => {
    createComponent();

    expect(findSnoozeDropdown().props('items')).toEqual([
      {
        items: [
          expect.objectContaining({
            formattedDate: 'Today, 2:24 PM',
            text: 'For one hour',
          }),
          expect.objectContaining({
            formattedDate: 'Today, 5:24 PM',
            text: 'Until later today',
          }),
          expect.objectContaining({
            formattedDate: 'Tomorrow, 8:00 AM',
            text: 'Until tomorrow',
          }),
          expect.objectContaining({
            formattedDate: 'Monday, 8:00 AM',
            text: 'Until next week',
          }),
        ],
        name: 'Snooze',
      },
      {
        items: [
          expect.objectContaining({
            text: 'Until a specific time and date',
          }),
        ],
      },
    ]);
  });

  it.each`
    index | expectedDate                  | expectedTrackingLabel
    ${0}  | ${'2024-12-18T14:24:00.000Z'} | ${'snooze_for_one_hour'}
    ${1}  | ${'2024-12-18T17:24:00.000Z'} | ${'snooze_until_later_today'}
    ${2}  | ${'2024-12-19T08:00:00.000Z'} | ${'snooze_until_tomorrow'}
    ${3}  | ${'2024-12-23T08:00:00.000Z'} | ${'snooze_until_next_week'}
  `(
    'triggers the snooze action with snoozeUntil = $expectedDate when clicking option #$index',
    ({ index, expectedDate, expectedTrackingLabel }) => {
      createComponent();
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      getPredefinedSnoozingOption(index).action();

      expect(wrapper.emitted()['snooze-until'][0]).toEqual([new Date(expectedDate)]);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_todo_item_action', {
        label: expectedTrackingLabel,
      });

      unmockTracking();
    },
  );

  it('has the correct props', () => {
    createComponent();

    expect(findSnoozeDropdown().props()).toMatchObject({
      toggleText: 'Snooze...',
      icon: 'clock',
      placement: 'bottom-end',
      textSrOnly: true,
      noCaret: true,
      fluidWidth: true,
    });
  });

  it('opens the custom snooze todo modal when clicking on the `Until a specific time and date` option', () => {
    createComponent();

    expect(SnoozeTodoModalStub.methods.show).not.toHaveBeenCalled();

    findSnoozeDropdown().props('items')[1].items[0].action();

    expect(SnoozeTodoModalStub.methods.show).toHaveBeenCalled();
  });

  it('attaches a tooltip to the dropdown toggle', () => {
    createComponent({ props: { isSnoozed: false, isPending: true } });
    const tooltip = findGlTooltip();

    expect(tooltip.exists()).toBe(true);
    expect(tooltip.text()).toBe('Snooze...');
  });

  it('only shows the tooltip when the dropdown is closed', async () => {
    createComponent({ props: { isSnoozed: false, isPending: true } });
    findSnoozeDropdown().vm.$emit('shown');
    await nextTick();

    expect(findGlTooltip().exists()).toBe(false);

    findSnoozeDropdown().vm.$emit('hidden');
    await nextTick();

    expect(findGlTooltip().exists()).toBe(true);
  });
});
