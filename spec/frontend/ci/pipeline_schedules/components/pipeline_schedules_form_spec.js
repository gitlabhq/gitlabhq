import MockAdapter from 'axios-mock-adapter';
import { GlForm } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import PipelineSchedulesForm from '~/ci/pipeline_schedules/components/pipeline_schedules_form.vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';
import { timezoneDataFixture } from '../../../vue_shared/components/timezone_dropdown/helpers';

describe('Pipeline schedules form', () => {
  let wrapper;
  const defaultBranch = 'main';
  const projectId = '1';
  const cron = '';
  const dailyLimit = '';

  const createComponent = (mountFn = shallowMountExtended, stubs = {}) => {
    wrapper = mountFn(PipelineSchedulesForm, {
      propsData: {
        timezoneData: timezoneDataFixture,
        refParam: 'master',
      },
      provide: {
        fullPath: 'gitlab-org/gitlab',
        projectId,
        defaultBranch,
        cron,
        cronTimezone: '',
        dailyLimit,
        settingsLink: '',
      },
      stubs,
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findDescription = () => wrapper.findByTestId('schedule-description');
  const findIntervalComponent = () => wrapper.findComponent(IntervalPatternInput);
  const findTimezoneDropdown = () => wrapper.findComponent(TimezoneDropdown);
  const findRefSelector = () => wrapper.findComponent(RefSelector);
  const findSubmitButton = () => wrapper.findByTestId('schedule-submit-button');
  const findCancelButton = () => wrapper.findByTestId('schedule-cancel-button');
  // Variables
  const findVariableRows = () => wrapper.findAllByTestId('ci-variable-row');
  const findKeyInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-key');
  const findValueInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-value');
  const findRemoveIcons = () => wrapper.findAllByTestId('remove-ci-variable-row');

  beforeEach(() => {
    createComponent();
  });

  describe('Form elements', () => {
    it('displays form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('displays the description input', () => {
      expect(findDescription().exists()).toBe(true);
    });

    it('displays the interval pattern component', () => {
      const intervalPattern = findIntervalComponent();

      expect(intervalPattern.exists()).toBe(true);
      expect(intervalPattern.props()).toMatchObject({
        initialCronInterval: cron,
        dailyLimit,
        sendNativeErrors: false,
      });
    });

    it('displays the Timezone dropdown', () => {
      const timezoneDropdown = findTimezoneDropdown();

      expect(timezoneDropdown.exists()).toBe(true);
      expect(timezoneDropdown.props()).toMatchObject({
        value: '',
        name: 'schedule-timezone',
        timezoneData: timezoneDataFixture,
      });
    });

    it('displays the branch/tag selector', () => {
      const refSelector = findRefSelector();

      expect(refSelector.exists()).toBe(true);
      expect(refSelector.props()).toMatchObject({
        enabledRefTypes: [REF_TYPE_BRANCHES, REF_TYPE_TAGS],
        value: defaultBranch,
        projectId,
        translations: { dropdownHeader: 'Select target branch or tag' },
        useSymbolicRefNames: true,
        state: true,
        name: '',
      });
    });

    it('displays the submit and cancel buttons', () => {
      expect(findSubmitButton().exists()).toBe(true);
      expect(findCancelButton().exists()).toBe(true);
    });
  });

  describe('CI variables', () => {
    let mock;

    const addVariableToForm = () => {
      const input = findKeyInputs().at(0);
      input.element.value = 'test_var_2';
      input.trigger('change');
    };

    beforeEach(() => {
      mock = new MockAdapter(axios);
      createComponent(mountExtended);
    });

    afterEach(() => {
      mock.restore();
    });

    it('creates blank variable on input change event', async () => {
      expect(findVariableRows()).toHaveLength(1);

      addVariableToForm();

      await nextTick();

      expect(findVariableRows()).toHaveLength(2);
      expect(findKeyInputs().at(1).element.value).toBe('');
      expect(findValueInputs().at(1).element.value).toBe('');
    });

    it('does not display remove icon for last row', async () => {
      addVariableToForm();

      await nextTick();

      expect(findRemoveIcons()).toHaveLength(1);
    });

    it('removes ci variable row on remove icon button click', async () => {
      addVariableToForm();

      await nextTick();

      expect(findVariableRows()).toHaveLength(2);

      findRemoveIcons().at(0).trigger('click');

      await nextTick();

      expect(findVariableRows()).toHaveLength(1);
    });
  });
});
