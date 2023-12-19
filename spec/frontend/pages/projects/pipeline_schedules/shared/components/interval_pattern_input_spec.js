import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
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

  const findEveryDayRadio = () => wrapper.findByTestId(everyDayKey);
  const findEveryWeekRadio = () => wrapper.findByTestId('everyWeek');
  const findEveryMonthRadio = () => wrapper.findByTestId('everyMonth');
  const findCustomRadio = () => wrapper.findByTestId(customKey);
  const findCustomInput = () => wrapper.find('#schedule_cron');
  const findAllLabels = () => wrapper.findAll('label');
  const findSelectedRadio = () =>
    wrapper.findAll('input[type="radio"]').wrappers.find((x) => x.element.checked);
  const findIcon = () => wrapper.findByTestId('daily-limit');
  const findSelectedRadioKey = () => findSelectedRadio()?.attributes('data-testid');
  const selectEveryDayRadio = () => findEveryDayRadio().setChecked(true);
  const selectEveryWeekRadio = () => findEveryWeekRadio().setChecked(true);
  const selectEveryMonthRadio = () => findEveryMonthRadio().setChecked(true);
  const selectCustomRadio = () => findCustomRadio().setChecked(true);

  const createWrapper = (props = {}, data = {}) => {
    wrapper = mountExtended(IntervalPatternInput, {
      propsData: { ...props },
      data() {
        return {
          randomMinute: data?.minute || mockMinute,
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
      ...window.gl,
      pipelineScheduleFieldErrors: {
        updateFormValidityState: jest.fn(),
      },
    };
  });

  afterEach(() => {
    window.gl = oldWindowGl;
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

  describe('formattedTime computed property', () => {
    it.each`
      desc                                                                                                    | hour  | minute | expectedValue
      ${'returns a time in the afternoon if the value of `random time` is higher than 12'}                    | ${13} | ${7}   | ${'1:07pm'}
      ${'returns a time in the morning if the value of `random time` is lower than 12'}                       | ${11} | ${30}  | ${'11:30am'}
      ${'returns "12:05pm" if the value of `random time` is exactly 12 and the value of random minutes is 5'} | ${12} | ${5}   | ${'12:05pm'}
    `('$desc', ({ hour, minute, expectedValue }) => {
      createWrapper({}, { hour, minute });

      expect(wrapper.vm.formattedTime).toBe(expectedValue);
    });
  });

  describe('Time strings', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders each label for radio options properly', () => {
      const labels = findAllLabels().wrappers.map((el) => trimText(el.text()));

      expect(labels).toEqual([
        'Every day (at 4:03am)',
        'Every week (Monday at 4:03am)',
        'Every month (Day 1 at 4:03am)',
        'Custom',
      ]);
    });
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

  describe('cronValue event', () => {
    it('emits cronValue event with cron value', async () => {
      createWrapper();

      findCustomInput().element.value = '0 16 * * *';
      findCustomInput().trigger('input');

      await nextTick();

      expect(wrapper.emitted()).toEqual({ cronValue: [['0 16 * * *']] });
    });
  });
});
