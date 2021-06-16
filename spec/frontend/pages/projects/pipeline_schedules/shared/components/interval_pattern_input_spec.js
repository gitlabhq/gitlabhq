import { GlIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
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
  const customKey = 'custom';
  const everyDayKey = 'everyDay';
  const cronIntervalNotInPreset = `0 12 * * *`;

  const findEveryDayRadio = () => wrapper.find(`[data-testid=${everyDayKey}]`);
  const findEveryWeekRadio = () => wrapper.find('[data-testid="everyWeek"]');
  const findEveryMonthRadio = () => wrapper.find('[data-testid="everyMonth"]');
  const findCustomRadio = () => wrapper.find(`[data-testid="${customKey}"]`);
  const findCustomInput = () => wrapper.find('#schedule_cron');
  const findAllLabels = () => wrapper.findAll('label');
  const findSelectedRadio = () =>
    wrapper.findAll('input[type="radio"]').wrappers.find((x) => x.element.checked);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findSelectedRadioKey = () => findSelectedRadio()?.attributes('data-testid');
  const selectEveryDayRadio = () => findEveryDayRadio().trigger('click');
  const selectEveryWeekRadio = () => findEveryWeekRadio().trigger('click');
  const selectEveryMonthRadio = () => findEveryMonthRadio().trigger('click');
  const selectCustomRadio = () => findCustomRadio().trigger('click');

  const createWrapper = (props = {}, data = {}) => {
    if (wrapper) {
      throw new Error('A wrapper already exists');
    }

    wrapper = mount(IntervalPatternInput, {
      propsData: { ...props },
      provide: {
        glFeatures: {
          ciDailyLimitForPipelineSchedules: true,
        },
      },
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

      await wrapper.vm.$nextTick();

      expect(findCustomInput().attributes('disabled')).toBeUndefined();
    });

    it('when the custom option is selected', async () => {
      selectCustomRadio();

      await wrapper.vm.$nextTick();

      expect(findCustomInput().attributes('disabled')).toBeUndefined();
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

  describe('Time strings', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders each label for radio options properly', () => {
      const labels = findAllLabels().wrappers.map((el) => trimText(el.text()));

      expect(labels).toEqual([
        'Every day (at 4:00am)',
        'Every week (Monday at 4:00am)',
        'Every month (Day 1 at 4:00am)',
        'Custom ( Cron syntax )',
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
        await wrapper.vm.$nextTick();
        expect(findCustomInput().element.value).toBe(cronIntervalPresets.everyWeek);

        selectEveryDayRadio();
        await wrapper.vm.$nextTick();
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

        await wrapper.vm.$nextTick();

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

      await wrapper.vm.$nextTick;

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
});
