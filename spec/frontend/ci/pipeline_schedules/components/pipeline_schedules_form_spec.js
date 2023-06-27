import MockAdapter from 'axios-mock-adapter';
import { GlForm } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import PipelineSchedulesForm from '~/ci/pipeline_schedules/components/pipeline_schedules_form.vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';
import createPipelineScheduleMutation from '~/ci/pipeline_schedules/graphql/mutations/create_pipeline_schedule.mutation.graphql';
import { timezoneDataFixture } from '../../../vue_shared/components/timezone_dropdown/helpers';
import { createScheduleMutationResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.fn().mockReturnValue(''),
}));

describe('Pipeline schedules form', () => {
  let wrapper;
  const defaultBranch = 'main';
  const projectId = '1';
  const cron = '';
  const dailyLimit = '';

  const createMutationHandlerSuccess = jest.fn().mockResolvedValue(createScheduleMutationResponse);
  const createMutationHandlerFailed = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const createMockApolloProvider = (
    requestHandlers = [[createPipelineScheduleMutation, createMutationHandlerSuccess]],
  ) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = (mountFn = shallowMountExtended, editing = false, requestHandlers) => {
    wrapper = mountFn(PipelineSchedulesForm, {
      propsData: {
        timezoneData: timezoneDataFixture,
        refParam: 'master',
        editing,
      },
      provide: {
        fullPath: 'gitlab-org/gitlab',
        projectId,
        defaultBranch,
        cron,
        cronTimezone: '',
        dailyLimit,
        settingsLink: '',
        schedulesPath: '/root/ci-project/-/pipeline_schedules',
      },
      apolloProvider: createMockApolloProvider(requestHandlers),
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

  const addVariableToForm = () => {
    const input = findKeyInputs().at(0);
    input.element.value = 'test_var_2';
    input.trigger('change');
  };

  describe('Form elements', () => {
    beforeEach(() => {
      createComponent();
    });

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
      expect(findCancelButton().attributes('href')).toBe('/root/ci-project/-/pipeline_schedules');
    });
  });

  describe('CI variables', () => {
    let mock;

    beforeEach(() => {
      // mock is needed when we fully mount
      // downstream components request needs to be mocked
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

  describe('schedule creation', () => {
    describe('schedule creation success', () => {
      let mock;

      beforeEach(() => {
        // mock is needed when we fully mount
        // downstream components request needs to be mocked
        mock = new MockAdapter(axios);
        createComponent(mountExtended);
      });

      afterEach(() => {
        mock.restore();
      });

      it('creates pipeline schedule', async () => {
        findDescription().element.value = 'My schedule';
        findDescription().trigger('change');

        findTimezoneDropdown().vm.$emit('input', {
          formattedTimezone: '[UTC-4] Eastern Time (US & Canada)',
          identifier: 'America/New_York',
        });

        findIntervalComponent().vm.$emit('cronValue', '0 16 * * *');

        addVariableToForm();

        findSubmitButton().vm.$emit('click');

        await waitForPromises();

        expect(createMutationHandlerSuccess).toHaveBeenCalledWith({
          input: {
            active: true,
            cron: '0 16 * * *',
            cronTimezone: 'America/New_York',
            description: 'My schedule',
            projectPath: 'gitlab-org/gitlab',
            ref: 'main',
            variables: [
              {
                key: 'test_var_2',
                value: '',
                variableType: 'ENV_VAR',
              },
            ],
          },
        });
        expect(visitUrl).toHaveBeenCalledWith('/root/ci-project/-/pipeline_schedules');
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('schedule creation failure', () => {
      beforeEach(() => {
        createComponent(shallowMountExtended, false, [
          [createPipelineScheduleMutation, createMutationHandlerFailed],
        ]);
      });

      it('shows error for failed pipeline schedule creation', async () => {
        findSubmitButton().vm.$emit('click');

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while creating the pipeline schedule.',
        });
      });
    });
  });
});
