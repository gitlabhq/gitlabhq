import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import TodoSnoozedTimestamp from '~/todos/components/todo_snoozed_timestamp.vue';
import { useFakeDate } from 'helpers/fake_date';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('TodoSnoozedTimestamp', () => {
  let wrapper;

  const mockCurrentTime = '2024-12-18T13:24:00';
  const mockForAnHour = '2024-12-18T14:24:00';
  const mockUntilLaterToday = '2024-12-18T17:24:00';
  const mockUntilTomorrow = '2024-12-19T08:00:00';
  const mockUntilNextWeek = '2024-12-25T08:00:00';
  const mockUntilLaterSameWeek = '2024-12-21T08:00:00';
  const mockYesterday = '2024-12-17T08:00:00';

  useFakeDate(mockCurrentTime);

  const findGlIcon = () => wrapper.findComponent(GlIcon);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TodoSnoozedTimestamp, {
      propsData: {
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const expectWithLabel = (label) => {
    const icon = findGlIcon();
    const tooltip = getBinding(icon.element, 'gl-tooltip');

    expect(tooltip).toBeDefined();
    expect(icon.props('name')).toBe('clock');
    expect(icon.attributes('title')).toBe(label);
    expect(icon.props('ariaLabel')).toBe(label);
  };

  it.each`
    snoozedUntil              | expectedLabel
    ${mockForAnHour}          | ${'Snoozed until 2:24 PM'}
    ${mockUntilLaterToday}    | ${'Snoozed until 5:24 PM'}
    ${mockUntilTomorrow}      | ${'Snoozed until tomorrow, 8:00 AM'}
    ${mockUntilLaterSameWeek} | ${'Snoozed until Saturday, 8:00 AM'}
    ${mockUntilNextWeek}      | ${'Snoozed until Dec 25, 2024'}
  `(
    'renders "$expectedLabel" when the item is snoozed until a future date ($snoozedUntil)',
    ({ snoozedUntil, expectedLabel }) => {
      createComponent({
        snoozedUntil,
        hasReachedSnoozeTimestamp: false,
      });

      expectWithLabel(expectedLabel);
    },
  );

  it('renders the timeago-formatted snoozed date when the item has reached its snooze time', () => {
    createComponent({
      snoozedUntil: mockYesterday,
      hasReachedSnoozeTimestamp: true,
    });

    expectWithLabel('Previously snoozed');
  });
});
