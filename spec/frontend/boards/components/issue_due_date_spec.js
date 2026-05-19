import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlTooltip } from '@gitlab/ui';
import { useFakeDate } from 'helpers/fake_date';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import { localeDateFormat, toISODateFormat } from '~/lib/utils/datetime_utility';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

const createComponent = ({ date = new Date(), startDate, closed = false } = {}) =>
  shallowMount(IssueDueDate, {
    propsData: {
      closed,
      startDate,
      date: toISODateFormat(date),
    },
    stubs: { WorkItemAttribute },
  });

const findTime = (wrapper) => wrapper.find('time');
const findIcon = (wrapper) => wrapper.findComponent(GlIcon);
const findTooltip = (wrapper) => wrapper.findComponent(GlTooltip);

describe('Issue Due Date component', () => {
  let wrapper;
  let date;

  beforeEach(() => {
    date = new Date();
  });

  it('should render "Today" if the due date is today', () => {
    wrapper = createComponent();

    expect(findTime(wrapper).text()).toBe('Today');
  });

  it('should render "Yesterday" if the due date is yesterday', () => {
    date.setDate(date.getDate() - 1);
    wrapper = createComponent({ date });

    expect(findTime(wrapper).text()).toBe('Yesterday');
  });

  it('should render "Tomorrow" if the due date is one day from now', () => {
    date.setDate(date.getDate() + 1);
    wrapper = createComponent({ date });

    expect(findTime(wrapper).text()).toBe('Tomorrow');
  });

  it('should render day of the week if due date is one week away', () => {
    date.setDate(date.getDate() + 5);
    wrapper = createComponent({ date });

    expect(findTime(wrapper).text()).toBe('Saturday');
  });

  it('should render month and day for other dates', () => {
    date.setDate(date.getDate() + 17);
    wrapper = createComponent({ date });
    const today = new Date();
    const expected =
      today.getFullYear() === date.getFullYear()
        ? localeDateFormat.asDateWithoutYear.format(date)
        : localeDateFormat.asDate.format(date);

    expect(findTime(wrapper).text()).toBe(expected);
  });

  it('should contain the correct icon for overdue issue that is open', () => {
    date.setDate(date.getDate() - 17);
    wrapper = createComponent({ date });

    expect(findIcon(wrapper).props()).toMatchObject({
      variant: 'danger',
      name: 'calendar-overdue',
    });
  });

  it('should not contain the overdue icon for overdue issue that is closed', () => {
    date.setDate(date.getDate() - 17);
    const closed = true;
    wrapper = createComponent({ date, closed });

    expect(findIcon(wrapper).props()).toMatchObject({
      variant: 'current',
      name: 'calendar',
    });
  });

  it('should contain the approaching icon when due date is within 6 days', () => {
    date.setDate(date.getDate() + 3);
    wrapper = createComponent({ date });

    expect(findIcon(wrapper).props()).toMatchObject({
      variant: 'warning',
      name: 'calendar-due',
    });
  });

  it('classifies today as approaching, not overdue', () => {
    wrapper = createComponent();

    expect(findIcon(wrapper).props()).toMatchObject({
      variant: 'warning',
      name: 'calendar-due',
    });
  });

  it('should not contain the approaching icon when due date is exactly 7 days away', () => {
    date.setDate(date.getDate() + 7);
    wrapper = createComponent({ date });

    expect(findIcon(wrapper).props()).toMatchObject({
      variant: 'current',
      name: 'calendar',
    });
  });

  it('should not contain the approaching icon when issue is closed', () => {
    date.setDate(date.getDate() + 3);
    wrapper = createComponent({ date, closed: true });

    expect(findIcon(wrapper).props()).toMatchObject({
      variant: 'current',
      name: 'calendar',
    });
  });

  it('includes "due soon" text in tooltip when approaching', () => {
    date.setDate(date.getDate() + 3);
    wrapper = createComponent({ date });

    expect(wrapper.text()).toContain('due soon');
  });

  describe('tooltip title (relative time)', () => {
    // July 6th, 2020 at 2:00 PM
    useFakeDate(2020, 6, 6, 14, 0, 0);

    it('describes a due date today as a future time, not a past one', () => {
      wrapper = createComponent({ date: new Date(2020, 6, 6) });

      const tooltipText = findTooltip(wrapper).text();
      expect(tooltipText).toMatch(/in \d+ hours?/);
      expect(tooltipText).not.toMatch(/hours? ago/);
    });

    it('describes a due date yesterday as "X hours ago" (relative to end-of-day)', () => {
      wrapper = createComponent({ date: new Date(2020, 6, 5) });

      expect(findTooltip(wrapper).text()).toMatch(/\d+ hours? ago/);
    });

    it('describes a due date two days ahead as "in 2 days"', () => {
      wrapper = createComponent({ date: new Date(2020, 6, 8) });

      expect(findTooltip(wrapper).text()).toContain('in 2 days');
    });
  });

  it('renders date range when start date is provided', () => {
    wrapper = createComponent({ date, startDate: '2020-02-02' });

    expect(wrapper.text()).toContain('Feb 2 – Jul 6, 2020');
  });
});
