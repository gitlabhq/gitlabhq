import { shallowMount } from '@vue/test-utils';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';

describe('Interval Pattern Input Component', () => {
  let oldWindowGl;
  let wrapper;

  const mockHour = 4;
  const mockWeekDayIndex = 1;
  const mockDay = 1;

  const cronIntervalPresets = {
    everyDay: `0 ${mockHour} * * *`,
    everyWeek: `0 ${mockHour} * * ${mockWeekDayIndex}`,
    everyMonth: `0 ${mockHour} ${mockDay} * *`,
  };

  const findEveryDayRadio = () => wrapper.find('#every-day');
  const findEveryWeekRadio = () => wrapper.find('#every-week');
  const findEveryMonthRadio = () => wrapper.find('#every-month');
  const findCustomRadio = () => wrapper.find('#custom');
  const findCustomInput = () => wrapper.find('#schedule_cron');
  const selectEveryDayRadio = () => findEveryDayRadio().setChecked();
  const selectEveryWeekRadio = () => findEveryWeekRadio().setChecked();
  const selectEveryMonthRadio = () => findEveryMonthRadio().setChecked();
  const selectCustomRadio = () => findCustomRadio().trigger('click');

  const createWrapper = (props = {}, data = {}) => {
    if (wrapper) {
      throw new Error('A wrapper already exists');
    }

    wrapper = shallowMount(IntervalPatternInput, {
      propsData: { ...props },
      data() {
        return {
          randomHour: data?.hour || mockHour,
          randomWeekDayIndex: mockWeekDayIndex,
          randomDay: mockDay,
        };
      },
    });
  };

  beforeEach(() => {
    oldWindowGl = window.gl;
    window.gl = {
      ...(window.gl || {}),
      pipelineScheduleFieldErrors: {
        updateFormValidityState: jest.fn(),
      },
    };
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    window.gl = oldWindowGl;
  });

  describe('the input field defaults', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('to a non empty string when no initial value is not passed', () => {
      expect(findCustomInput()).not.toBe('');
    });
  });

  describe('the input field', () => {
    const initialCron = '0 * * * *';

    beforeEach(() => {
      createWrapper({ initialCronInterval: initialCron });
    });

    it('is equal to the prop `initialCronInterval` when passed', () => {
      expect(findCustomInput().element.value).toBe(initialCron);
    });
  });

  describe('The input field is enabled', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('when a default option is selected', () => {
      selectEveryDayRadio();

      return wrapper.vm.$nextTick().then(() => {
        expect(findCustomInput().attributes('disabled')).toBeUndefined();
      });
    });

    it('when the custom option is selected', () => {
      selectCustomRadio();

      return wrapper.vm.$nextTick().then(() => {
        expect(findCustomInput().attributes('disabled')).toBeUndefined();
      });
    });
  });

  describe('formattedTime computed property', () => {
    it.each`
      desc                                                                                 | hour  | expectedValue
      ${'returns a time in the afternoon if the value of `random time` is higher than 12'} | ${13} | ${'1:00pm'}
      ${'returns a time in the morning if the value of `random time` is lower than 12'}    | ${11} | ${'11:00am'}
      ${'returns "12:00pm" if the value of `random time` is exactly 12'}                   | ${12} | ${'12:00pm'}
    `('$desc', ({ hour, expectedValue }) => {
      createWrapper({}, { hour });

      expect(wrapper.vm.formattedTime).toBe(expectedValue);
    });
  });

  describe('User Actions with radio buttons', () => {
    it.each`
      desc                                             | initialCronInterval               | act                      | expectedValue
      ${'when everyday is selected, update value'}     | ${'1 2 3 4 5'}                    | ${selectEveryDayRadio}   | ${cronIntervalPresets.everyDay}
      ${'when everyweek is selected, update value'}    | ${'1 2 3 4 5'}                    | ${selectEveryWeekRadio}  | ${cronIntervalPresets.everyWeek}
      ${'when everymonth is selected, update value'}   | ${'1 2 3 4 5'}                    | ${selectEveryMonthRadio} | ${cronIntervalPresets.everyMonth}
      ${'when custom is selected, add space to value'} | ${cronIntervalPresets.everyMonth} | ${selectCustomRadio}     | ${`${cronIntervalPresets.everyMonth} `}
    `('$desc', ({ initialCronInterval, act, expectedValue }) => {
      createWrapper({ initialCronInterval });

      act();

      return wrapper.vm.$nextTick().then(() => {
        expect(findCustomInput().element.value).toBe(expectedValue);
      });
    });
  });
  describe('User actions with input field for Cron syntax', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('when editing the cron input it selects the custom radio button', () => {
      const newValue = '0 * * * *';

      findCustomInput().setValue(newValue);

      expect(wrapper.vm.cronInterval).toBe(newValue);
    });

    it('when value of input is one of the defaults, it selects the corresponding radio button', () => {
      findCustomInput().setValue(cronIntervalPresets.everyWeek);

      expect(wrapper.vm.cronInterval).toBe(cronIntervalPresets.everyWeek);
    });
  });
});
