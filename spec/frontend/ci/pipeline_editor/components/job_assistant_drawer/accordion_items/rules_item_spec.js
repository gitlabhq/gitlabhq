import { GlLink, GlSprintf } from '@gitlab/ui';
import RulesItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/rules_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  JOB_TEMPLATE,
  JOB_RULES_WHEN,
  JOB_RULES_START_IN,
  HELP_PATHS,
} from '~/ci/pipeline_editor/components/job_assistant_drawer/constants';

describe('Rules item', () => {
  let wrapper;

  const findLink = () => wrapper.findComponent(GlLink);
  const findRulesWhenSelect = () => wrapper.findByTestId('rules-when-select');
  const findRulesStartInNumberInput = () => wrapper.findByTestId('rules-start-in-number-input');
  const findRulesStartInUnitSelect = () => wrapper.findByTestId('rules-start-in-unit-select');
  const findRulesAllowFailureCheckBox = () => wrapper.findByTestId('rules-allow-failure-checkbox');

  const dummyRulesWhen = JOB_RULES_WHEN.delayed.value;
  const dummyRulesStartInNumber = 2;
  const dummyRulesStartInUnit = JOB_RULES_START_IN.week.value;
  const dummyRulesAllowFailure = true;

  const createComponent = () => {
    wrapper = shallowMountExtended(RulesItem, {
      propsData: {
        isStartValid: true,
        job: JSON.parse(JSON.stringify(JOB_TEMPLATE)),
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should render help link with correct href', () => {
    createComponent();

    expect(findLink().attributes('href')).toEqual(HELP_PATHS.rulesHelpPath);
  });

  it('should emit update job event when filling inputs', () => {
    expect(wrapper.emitted('update-job')).toBeUndefined();

    findRulesWhenSelect().vm.$emit('input', dummyRulesWhen);

    expect(wrapper.emitted('update-job')).toHaveLength(2);
    expect(wrapper.emitted('update-job')[0]).toEqual([
      'rules[0].when',
      JOB_RULES_WHEN.delayed.value,
    ]);
    expect(wrapper.emitted('update-job')[1]).toEqual([
      'rules[0].start_in',
      `1 ${JOB_RULES_START_IN.second.value}`,
    ]);

    findRulesStartInNumberInput().vm.$emit('input', dummyRulesStartInNumber);

    expect(wrapper.emitted('update-job')).toHaveLength(3);
    expect(wrapper.emitted('update-job')[2]).toEqual([
      'rules[0].start_in',
      `2 ${JOB_RULES_START_IN.second.value}s`,
    ]);

    findRulesStartInUnitSelect().vm.$emit('input', dummyRulesStartInUnit);

    expect(wrapper.emitted('update-job')).toHaveLength(4);
    expect(wrapper.emitted('update-job')[3]).toEqual([
      'rules[0].start_in',
      `2 ${dummyRulesStartInUnit}s`,
    ]);

    findRulesAllowFailureCheckBox().vm.$emit('input', dummyRulesAllowFailure);

    expect(wrapper.emitted('update-job')).toHaveLength(5);
    expect(wrapper.emitted('update-job')[4]).toEqual([
      'rules[0].allow_failure',
      dummyRulesAllowFailure,
    ]);
  });
});
