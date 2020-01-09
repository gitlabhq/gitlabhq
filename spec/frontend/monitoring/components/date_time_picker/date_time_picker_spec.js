import { mount } from '@vue/test-utils';
import DateTimePicker from '~/monitoring/components/date_time_picker/date_time_picker.vue';
import { timeWindows } from '~/monitoring/constants';

const timeWindowsCount = Object.keys(timeWindows).length;
const start = '2019-10-10T07:00:00.000Z';
const end = '2019-10-13T07:00:00.000Z';
const selectedTimeWindowText = `3 days`;

describe('DateTimePicker', () => {
  let dateTimePicker;

  const dropdownToggle = () => dateTimePicker.find('.dropdown-toggle');
  const dropdownMenu = () => dateTimePicker.find('.dropdown-menu');
  const applyButtonElement = () => dateTimePicker.find('button[variant="success"]').element;
  const cancelButtonElement = () => dateTimePicker.find('button.btn-secondary').element;
  const fillInputAndBlur = (input, val) => {
    dateTimePicker.find(input).setValue(val);
    return dateTimePicker.vm.$nextTick().then(() => {
      dateTimePicker.find(input).trigger('blur');
      return dateTimePicker.vm.$nextTick();
    });
  };

  const createComponent = props => {
    dateTimePicker = mount(DateTimePicker, {
      propsData: {
        timeWindows,
        start,
        end,
        ...props,
      },
      sync: false,
    });
  };

  afterEach(() => {
    dateTimePicker.destroy();
  });

  it('renders dropdown toggle button with selected text', done => {
    createComponent();
    dateTimePicker.vm.$nextTick(() => {
      expect(dropdownToggle().text()).toBe(selectedTimeWindowText);
      done();
    });
  });

  it('renders dropdown with 2 custom time range inputs', () => {
    createComponent();
    dateTimePicker.vm.$nextTick(() => {
      expect(dateTimePicker.findAll('input').length).toBe(2);
    });
  });

  it('renders dropdown without a selectedTimeWindow set', done => {
    createComponent({
      selectedTimeWindow: {},
    });
    dateTimePicker.vm.$nextTick(() => {
      expect(dateTimePicker.findAll('input').length).toBe(2);
      done();
    });
  });

  it('renders inputs with h/m/s truncated if its all 0s', done => {
    createComponent({
      start: '2019-10-10T00:00:00.000Z',
      end: '2019-10-14T00:10:00.000Z',
    });
    dateTimePicker.vm.$nextTick(() => {
      expect(dateTimePicker.find('#custom-time-from').element.value).toBe('2019-10-10');
      expect(dateTimePicker.find('#custom-time-to').element.value).toBe('2019-10-14 00:10:00');
      done();
    });
  });

  it(`renders dropdown with ${timeWindowsCount} items in quick range`, done => {
    createComponent();
    dropdownToggle().trigger('click');
    dateTimePicker.vm.$nextTick(() => {
      expect(dateTimePicker.findAll('.dropdown-item').length).toBe(timeWindowsCount);
      done();
    });
  });

  it(`renders dropdown with correct quick range item selected`, done => {
    createComponent();
    dropdownToggle().trigger('click');
    dateTimePicker.vm.$nextTick(() => {
      expect(dateTimePicker.find('.dropdown-item.active').text()).toBe(selectedTimeWindowText);

      expect(dateTimePicker.find('.dropdown-item.active svg').isVisible()).toBe(true);
      done();
    });
  });

  it('renders a disabled apply button on wrong input', () => {
    createComponent({
      start: 'invalid-input-date',
    });

    expect(applyButtonElement().getAttribute('disabled')).toBe('disabled');
  });

  it('displays inline error message if custom time range inputs are invalid', done => {
    createComponent();
    fillInputAndBlur('#custom-time-from', '2019-10-01abc')
      .then(() => fillInputAndBlur('#custom-time-to', '2019-10-10abc'))
      .then(() => {
        expect(dateTimePicker.findAll('.invalid-feedback').length).toBe(2);
        done();
      })
      .catch(done);
  });

  it('keeps apply button disabled with invalid custom time range inputs', done => {
    createComponent();
    fillInputAndBlur('#custom-time-from', '2019-10-01abc')
      .then(() => fillInputAndBlur('#custom-time-to', '2019-09-19'))
      .then(() => {
        expect(applyButtonElement().getAttribute('disabled')).toBe('disabled');
        done();
      })
      .catch(done);
  });

  it('enables apply button with valid custom time range inputs', done => {
    createComponent();
    fillInputAndBlur('#custom-time-from', '2019-10-01')
      .then(() => fillInputAndBlur('#custom-time-to', '2019-10-19'))
      .then(() => {
        expect(applyButtonElement().getAttribute('disabled')).toBeNull();
        done();
      })
      .catch(done.fail);
  });

  it('emits dates in an object when apply is clicked', done => {
    createComponent();
    fillInputAndBlur('#custom-time-from', '2019-10-01')
      .then(() => fillInputAndBlur('#custom-time-to', '2019-10-19'))
      .then(() => {
        applyButtonElement().click();

        expect(dateTimePicker.emitted().apply).toHaveLength(1);
        expect(dateTimePicker.emitted().apply[0]).toEqual([
          {
            end: '2019-10-19T00:00:00Z',
            start: '2019-10-01T00:00:00Z',
          },
        ]);
        done();
      })
      .catch(done.fail);
  });

  it('hides the popover with cancel button', done => {
    createComponent();
    dropdownToggle().trigger('click');

    dateTimePicker.vm.$nextTick(() => {
      cancelButtonElement().click();

      dateTimePicker.vm.$nextTick(() => {
        expect(dropdownMenu().classes('show')).toBe(false);
        done();
      });
    });
  });
});
