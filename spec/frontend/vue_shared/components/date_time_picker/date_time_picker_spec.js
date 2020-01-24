import { mount } from '@vue/test-utils';
import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import { defaultTimeWindows } from '~/vue_shared/components/date_time_picker/date_time_picker_lib';

const timeWindowsCount = Object.entries(defaultTimeWindows).length;
const start = '2019-10-10T07:00:00.000Z';
const end = '2019-10-13T07:00:00.000Z';
const selectedTimeWindowText = `3 days`;

describe('DateTimePicker', () => {
  let dateTimePicker;

  const dropdownToggle = () => dateTimePicker.find('.dropdown-toggle');
  const dropdownMenu = () => dateTimePicker.find('.dropdown-menu');
  const applyButtonElement = () => dateTimePicker.find('button.btn-success').element;
  const findQuickRangeItems = () => dateTimePicker.findAll('.dropdown-item');
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
        start,
        end,
        ...props,
      },
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

  it(`renders dropdown with ${timeWindowsCount} (default) items in quick range`, done => {
    createComponent();
    dropdownToggle().trigger('click');
    dateTimePicker.vm.$nextTick(() => {
      expect(findQuickRangeItems().length).toBe(timeWindowsCount);
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

  describe('when using non-default time windows', () => {
    const otherTimeWindows = {
      oneMinute: {
        label: '1 minute',
        seconds: 60,
      },
      twoMinutes: {
        label: '2 minutes',
        seconds: 60 * 2,
        default: true,
      },
      fiveMinutes: {
        label: '5 minutes',
        seconds: 60 * 5,
      },
    };

    it('renders dropdown with a label in the quick range', done => {
      createComponent({
        // 2 minutes range
        start: '2020-01-21T15:00:00.000Z',
        end: '2020-01-21T15:02:00.000Z',
        timeWindows: otherTimeWindows,
      });
      dropdownToggle().trigger('click');
      dateTimePicker.vm.$nextTick(() => {
        expect(dropdownToggle().text()).toBe('2 minutes');

        done();
      });
    });

    it('renders dropdown with quick range items', done => {
      createComponent({
        // 2 minutes range
        start: '2020-01-21T15:00:00.000Z',
        end: '2020-01-21T15:02:00.000Z',
        timeWindows: otherTimeWindows,
      });
      dropdownToggle().trigger('click');
      dateTimePicker.vm.$nextTick(() => {
        const items = findQuickRangeItems();

        expect(items.length).toBe(Object.keys(otherTimeWindows).length);
        expect(items.at(0).text()).toBe('1 minute');
        expect(items.at(0).is('.active')).toBe(false);

        expect(items.at(1).text()).toBe('2 minutes');
        expect(items.at(1).is('.active')).toBe(true);

        expect(items.at(2).text()).toBe('5 minutes');
        expect(items.at(2).is('.active')).toBe(false);

        done();
      });
    });

    it('renders dropdown with a label not in the quick range', done => {
      createComponent({
        // 10 minutes range
        start: '2020-01-21T15:00:00.000Z',
        end: '2020-01-21T15:10:00.000Z',
        timeWindows: otherTimeWindows,
      });
      dropdownToggle().trigger('click');
      dateTimePicker.vm.$nextTick(() => {
        expect(dropdownToggle().text()).toBe('2020-01-21 15:00:00 to 2020-01-21 15:10:00');

        done();
      });
    });
  });
});
