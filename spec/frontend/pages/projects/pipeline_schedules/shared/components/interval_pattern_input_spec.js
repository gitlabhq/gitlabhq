import { shallowMount } from '@vue/test-utils';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';

const cronIntervalPresets = {
  everyDay: '0 4 * * *',
  everyWeek: '0 4 * * 0',
  everyMonth: '0 4 1 * *',
};

describe('Interval Pattern Input Component', () => {
  let oldWindowGl;
  let wrapper;

  const findEveryDayRadio = () => wrapper.find('#every-day');
  const findEveryWeekRadio = () => wrapper.find('#every-week');
  const findEveryMonthRadio = () => wrapper.find('#every-month');
  const findCustomRadio = () => wrapper.find('#custom');
  const findCustomInput = () => wrapper.find('#schedule_cron');
  const selectEveryDayRadio = () => findEveryDayRadio().setChecked();
  const selectEveryWeekRadio = () => findEveryWeekRadio().setChecked();
  const selectEveryMonthRadio = () => findEveryMonthRadio().setChecked();
  const selectCustomRadio = () => findCustomRadio().trigger('click');

  const createWrapper = (props = {}) => {
    if (wrapper) {
      throw new Error('A wrapper already exists');
    }

    wrapper = shallowMount(IntervalPatternInput, {
      propsData: { ...props },
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

  describe('when prop initialCronInterval is passed', () => {
    describe('and prop initialCronInterval is custom', () => {
      beforeEach(() => {
        createWrapper({ initialCronInterval: '1 2 3 4 5' });
      });

      it('the input is enabled', () => {
        expect(findCustomInput().attributes('disabled')).toBeUndefined();
      });
    });

    describe('and prop initialCronInterval is a preset', () => {
      beforeEach(() => {
        createWrapper({ initialCronInterval: cronIntervalPresets.everyDay });
      });

      it('the input is disabled', () => {
        expect(findCustomInput().attributes('disabled')).toBe('disabled');
      });
    });
  });

  describe('when prop initialCronInterval is not passed', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('the input is enabled since custom is default value', () => {
      expect(findCustomInput().attributes('disabled')).toBeUndefined();
    });
  });

  describe('User Actions', () => {
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
});
