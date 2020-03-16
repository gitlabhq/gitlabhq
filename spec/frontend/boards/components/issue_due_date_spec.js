import { shallowMount } from '@vue/test-utils';
import dateFormat from 'dateformat';
import IssueDueDate from '~/boards/components/issue_due_date.vue';

const createComponent = (dueDate = new Date(), closed = false) =>
  shallowMount(IssueDueDate, {
    propsData: {
      closed,
      date: dateFormat(dueDate, 'yyyy-mm-dd', true),
    },
  });

const findTime = wrapper => wrapper.find('time');

describe('Issue Due Date component', () => {
  let wrapper;
  let date;

  beforeEach(() => {
    date = new Date();
  });

  afterEach(() => {
    wrapper.destroy();
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

    expect(findTime(wrapper).text()).toBe(dateFormat(date, 'dddd'));
  });

  it('should render month and day for other dates', () => {
    date.setDate(date.getDate() + 17);
    wrapper = createComponent(date);
    const today = new Date();
    const isDueInCurrentYear = today.getFullYear() === date.getFullYear();
    const format = isDueInCurrentYear ? 'mmm d' : 'mmm d, yyyy';

    expect(findTime(wrapper).text()).toBe(dateFormat(date, format));
  });

  it('should contain the correct `.text-danger` css class for overdue issue that is open', () => {
    date.setDate(date.getDate() - 17);
    wrapper = createComponent(date);

    expect(findTime(wrapper).classes('text-danger')).toBe(true);
  });

  it('should not contain the `.text-danger` css class for overdue issue that is closed', () => {
    date.setDate(date.getDate() - 17);
    const closed = true;
    wrapper = createComponent(date, closed);

    expect(findTime(wrapper).classes('text-danger')).toBe(false);
  });
});
