import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { setLanguage } from 'jest/__helpers__/locale_helper';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';

describe('Interval Pattern Input Component', () => {
  let oldWindowGl;
  let wrapper;

  const mockMinute = 3;
  const mockHour = 4;
  const mockWeekDayIndex = 1;
  const mockDay = 1;

  const cronIntervalPresets = {
    everyDay: `${mockMinute} ${mockHour} * * *`,
    everyWeek: `${mockMinute} ${mockHour} * * ${mockWeekDayIndex}`,
    everyMonth: `${mockMinute} ${mockHour} ${mockDay} * *`,
  };
  const customKey = 'custom';
  const everyDayKey = 'everyDay';
  const cronIntervalNotInPreset = `0 12 * * *`;
  const workerCronValue = '3-59/10 * * * *';

  const findEveryDayRadio = () => wrapper.findByTestId(everyDayKey);
  const findEveryWeekRadio = () => wrapper.findByTestId('everyWeek');
  const findEveryMonthRadio = () => wrapper.findByTestId('everyMonth');
  const findCustomRadio = () => wrapper.findByTestId(customKey);
  const findCustomInput = () => wrapper.find('#schedule_cron');
  const findAllLabels = () => wrapper.findAll('label');
  const findLabelTexts = () =>
    findAllLabels().wrappers.map((el) => el.text().replace(/\s+/g, ' ').trim());
  const findSelectedRadio = () =>
    wrapper.findAll('input[type="radio"]').wrappers.find((x) => x.element.checked);
  const findIcon = () => wrapper.findByTestId('daily-limit');
  const findSelectedRadioKey = () => findSelectedRadio()?.attributes('data-testid');
  const selectEveryDayRadio = () => findEveryDayRadio().setChecked(true);
  const selectEveryWeekRadio = () => findEveryWeekRadio().setChecked(true);
  const selectEveryMonthRadio = () => findEveryMonthRadio().setChecked(true);
  const selectCustomRadio = () => findCustomRadio().setChecked(true);
  const findWorkerCronExpressionHint = () => wrapper.findByTestId('worker-cron-expression-hint');

  const createWrapper = (props = {}, data = {}) => {
    wrapper = mountExtended(IntervalPatternInput, {
      propsData: { ...props },
      data() {
        return {
          randomMinute: data?.minute ?? mockMinute,
          randomHour: data?.hour ?? mockHour,
          randomWeekDayIndex: mockWeekDayIndex,
          randomDay: mockDay,
        };
      },
      provide: {
        workerCronExpression: workerCronValue,
      },
    });
  };

  beforeEach(() => {
    oldWindowGl = window.gl;
    window.gl = {
      ...window.gl,
      pipelineScheduleFieldErrors: {
        updateFormValidityState: jest.fn(),
      },
    };
  });

  afterEach(() => {
    window.gl = oldWindowGl;
  });

  describe('the worker cron expression hint', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays the expected value', () => {
      expect(findWorkerCronExpressionHint().exists()).toBe(true);
      expect(findWorkerCronExpressionHint().text()).toContain(workerCronValue);
    });
  });

  describe('the input field defaults', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('defaults to every day value when no `initialCronInterval` is passed', () => {
      expect(findCustomInput().element.value).toBe(cronIntervalPresets.everyDay);
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

    it('when a default option is selected', async () => {
      selectEveryDayRadio();

      await nextTick();

      expect(findCustomInput().attributes('disabled')).toBeUndefined();
    });

    it('when the custom option is selected', async () => {
      selectCustomRadio();

      await nextTick();

      expect(findCustomInput().attributes('disabled')).toBeUndefined();
    });
  });

  describe('Time strings', () => {
    const presetTimes = [
      { hour: 0, minute: 5 },
      { hour: 4, minute: 3 },
      { hour: 12, minute: 5 },
      { hour: 13, minute: 7 },
    ];

    afterEach(() => {
      setLanguage(null);
      localeDateFormat.reset();
    });

    describe.each`
      preference   | timeDisplayFormat | language   | expectedTimes
      ${'unset'}   | ${undefined}      | ${'en-US'} | ${['12:05 AM', '4:03 AM', '12:05 PM', '1:07 PM']}
      ${'unset'}   | ${undefined}      | ${'de-DE'} | ${['00:05', '04:03', '12:05', '13:07']}
      ${'System'}  | ${0}              | ${'en-US'} | ${['12:05 AM', '4:03 AM', '12:05 PM', '1:07 PM']}
      ${'System'}  | ${0}              | ${'de-DE'} | ${['00:05', '04:03', '12:05', '13:07']}
      ${'12-hour'} | ${1}              | ${'en-US'} | ${['12:05 AM', '4:03 AM', '12:05 PM', '1:07 PM']}
      ${'12-hour'} | ${1}              | ${'de-DE'} | ${['12:05 AM', '04:03 AM', '12:05 PM', '01:07 PM']}
      ${'24-hour'} | ${2}              | ${'en-US'} | ${['00:05', '04:03', '12:05', '13:07']}
      ${'24-hour'} | ${2}              | ${'de-DE'} | ${['00:05', '04:03', '12:05', '13:07']}
    `(
      'when the time format preference is $preference and the language is $language',
      ({ timeDisplayFormat, language, expectedTimes }) => {
        beforeEach(() => {
          window.gon.time_display_format = timeDisplayFormat;
          setLanguage(language);
          localeDateFormat.reset();
        });

        it.each(
          presetTimes.map((time, index) => ({ ...time, expectedTime: expectedTimes[index] })),
        )(
          'renders hour $hour, minute $minute as $expectedTime in each preset label',
          ({ hour, minute, expectedTime }) => {
            createWrapper({}, { hour, minute });

            expect(findLabelTexts()).toEqual([
              `Every day (at ${expectedTime})`,
              `Every week (Monday at ${expectedTime})`,
              `Every month (Day 1 at ${expectedTime})`,
              'Custom',
            ]);
            expect(findCustomInput().element.value).toBe(`${minute} ${hour} * * *`);
          },
        );
      },
    );
  });

  describe('User Actions with radio buttons', () => {
    describe('Default option', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('when everyday is selected, update value', async () => {
        selectEveryWeekRadio();
        await nextTick();
        expect(findCustomInput().element.value).toBe(cronIntervalPresets.everyWeek);

        selectEveryDayRadio();
        await nextTick();
        expect(findCustomInput().element.value).toBe(cronIntervalPresets.everyDay);
      });
    });

    describe('Other options', () => {
      it.each`
        desc                                                 | initialCronInterval               | act                      | expectedValue
        ${'when everyweek is selected, update value'}        | ${'1 2 3 4 5'}                    | ${selectEveryWeekRadio}  | ${cronIntervalPresets.everyWeek}
        ${'when everymonth is selected, update value'}       | ${'1 2 3 4 5'}                    | ${selectEveryMonthRadio} | ${cronIntervalPresets.everyMonth}
        ${'when custom is selected, value remains the same'} | ${cronIntervalPresets.everyMonth} | ${selectCustomRadio}     | ${cronIntervalPresets.everyMonth}
      `('$desc', async ({ initialCronInterval, act, expectedValue }) => {
        createWrapper({ initialCronInterval });

        act();

        await nextTick();

        expect(findCustomInput().element.value).toBe(expectedValue);
      });
    });
  });

  describe('User actions with input field for Cron syntax', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('when editing the cron input it selects the custom radio button', async () => {
      const newValue = '0 * * * *';

      expect(findSelectedRadioKey()).toBe(everyDayKey);

      findCustomInput().setValue(newValue);

      await nextTick();

      expect(findSelectedRadioKey()).toBe(customKey);
    });
  });

  describe('Edit form field', () => {
    beforeEach(() => {
      createWrapper({ initialCronInterval: cronIntervalNotInPreset });
    });

    it('loads with the custom option being selected', () => {
      expect(findSelectedRadioKey()).toBe(customKey);
    });
  });

  describe('Custom cron syntax quota info', () => {
    it('the info message includes 5 minutes', () => {
      createWrapper({ dailyLimit: '288' });

      expect(findIcon().attributes('title')).toContain('5 minutes');
    });

    it('the info message includes 60 minutes', () => {
      createWrapper({ dailyLimit: '24' });

      expect(findIcon().attributes('title')).toContain('60 minutes');
    });

    it('the info message icon is not shown when there is no daily limit', () => {
      createWrapper();

      expect(findIcon().exists()).toBe(false);
    });
  });

  describe('cron-value event', () => {
    it('emits cron-value event with cron value', async () => {
      // Provide initial value to prevent immediate watch trigger
      createWrapper({
        initialCronInterval: '0 * * * *',
      });

      findCustomInput().element.value = '0 16 * * *';
      findCustomInput().trigger('input');

      await nextTick();

      expect(wrapper.emitted()).toEqual({ 'cron-value': [['0 16 * * *']] });
    });
  });

  describe('Random day-of-month generation', () => {
    // Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/502445
    // Day-of-month in cron must be 1-31; 0 is invalid syntax.
    const mountWithoutDataOverride = () =>
      mountExtended(IntervalPatternInput, {
        provide: { workerCronExpression: workerCronValue },
      });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('produces day 1 when Math.random returns 0 (never 0 which is invalid cron syntax)', () => {
      jest.spyOn(global.Math, 'random').mockReturnValue(0);
      wrapper = mountWithoutDataOverride();

      expect(wrapper.vm.randomDay).toBe(1);
    });

    it('produces day 28 at the upper bound (safe for every month)', () => {
      jest.spyOn(global.Math, 'random').mockReturnValue(0.99999);
      wrapper = mountWithoutDataOverride();

      expect(wrapper.vm.randomDay).toBe(28);
    });
  });
});
