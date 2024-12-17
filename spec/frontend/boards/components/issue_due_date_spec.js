import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import { localeDateFormat, toISODateFormat } from '~/lib/utils/datetime_utility';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

const createComponent = (dueDate = new Date(), closed = false) =>
  shallowMount(IssueDueDate, {
    propsData: {
      closed,
      date: toISODateFormat(dueDate),
    },
    stubs: { WorkItemAttribute },
  });

const findTime = (wrapper) => wrapper.find('time');
const findIcon = (wrapper) => wrapper.findComponent(GlIcon);

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
    wrapper = createComponent(date);

    expect(findTime(wrapper).text()).toBe('Yesterday');
  });

  it('should render "Tomorrow" if the due date is one day from now', () => {
    date.setDate(date.getDate() + 1);
    wrapper = createComponent(date);

    expect(findTime(wrapper).text()).toBe('Tomorrow');
  });

  it('should render day of the week if due date is one week away', () => {
    date.setDate(date.getDate() + 5);
    wrapper = createComponent(date);

    expect(findTime(wrapper).text()).toBe('Saturday');
  });

  it('should render month and day for other dates', () => {
    date.setDate(date.getDate() + 17);
    wrapper = createComponent(date);
    const today = new Date();
    const expected =
      today.getFullYear() === date.getFullYear()
        ? localeDateFormat.asDateWithoutYear.format(date)
        : localeDateFormat.asDate.format(date);

    expect(findTime(wrapper).text()).toBe(expected);
  });

  it('should contain the correct icon for overdue issue that is open', () => {
    date.setDate(date.getDate() - 17);
    wrapper = createComponent(date);

    expect(findIcon(wrapper).props()).toMatchObject({
      variant: 'danger',
      name: 'calendar-overdue',
    });
  });

  it('should not contain the overdue icon for overdue issue that is closed', () => {
    date.setDate(date.getDate() - 17);
    const closed = true;
    wrapper = createComponent(date, closed);

    expect(findIcon(wrapper).props()).toMatchObject({
      variant: 'subtle',
      name: 'calendar',
    });
  });
});
