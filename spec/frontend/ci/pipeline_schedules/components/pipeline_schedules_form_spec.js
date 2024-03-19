import MockAdapter from 'axios-mock-adapter';
import { GlForm, GlLoadingIcon } from '@gitlab/ui';
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
import updatePipelineScheduleMutation from '~/ci/pipeline_schedules/graphql/mutations/update_pipeline_schedule.mutation.graphql';
import getPipelineSchedulesQuery from '~/ci/pipeline_schedules/graphql/queries/get_pipeline_schedules.query.graphql';
import { timezoneDataFixture } from '../../../vue_shared/components/timezone_dropdown/helpers';
import {
  createScheduleMutationResponse,
  updateScheduleMutationResponse,
  mockSinglePipelineScheduleNode,
  mockSinglePipelineScheduleNodeNoVars,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.fn().mockReturnValue(''),
  queryToObject: jest.fn().mockReturnValue({ id: '1' }),
}));

const {
  data: {
    project: {
      pipelineSchedules: { nodes },
    },
  },
} = mockSinglePipelineScheduleNode;

const schedule = nodes[0];
const variables = schedule.variables.nodes;

describe('Pipeline schedules form', () => {
  let wrapper;
  const defaultBranch = 'main';
  const projectId = '1';
  const cron = '';
  const dailyLimit = '';

  const querySuccessHandler = jest.fn().mockResolvedValue(mockSinglePipelineScheduleNode);
  const querySuccessEmptyVarsHandler = jest
    .fn()
    .mockResolvedValue(mockSinglePipelineScheduleNodeNoVars);
  const queryFailedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const createMutationHandlerSuccess = jest.fn().mockResolvedValue(createScheduleMutationResponse);
  const createMutationHandlerFailed = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const updateMutationHandlerSuccess = jest.fn().mockResolvedValue(updateScheduleMutationResponse);
  const updateMutationHandlerFailed = jest.fn().mockRejectedValue(new Error('GraphQL error'));

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
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  // Variables
  const findVariableRows = () => wrapper.findAllByTestId('ci-variable-row');
  const findVariableTypes = () => wrapper.findAllByTestId('pipeline-form-ci-variable-type');
  const findKeyInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-key');
  const findValueInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-value');
  const findHiddenValueInputs = () =>
    wrapper.findAllByTestId('pipeline-form-ci-variable-hidden-value');
  const findVariableSecurityBtn = () => wrapper.findByTestId('variable-security-btn');

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

    it('changes variable type', async () => {
      expect(findVariableTypes().at(0).props('selected')).toBe('ENV_VAR');

      findVariableTypes().at(0).vm.$emit('select', 'FILE');

      await nextTick();

      expect(findVariableTypes().at(0).props('selected')).toBe('FILE');
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

  describe('Button text', () => {
    it.each`
      editing  | expectedText
      ${true}  | ${'Save changes'}
      ${false} | ${'Create pipeline schedule'}
    `(
      'button text is $expectedText when editing is $editing',
      async ({ editing, expectedText }) => {
        createComponent(shallowMountExtended, editing, [
          [getPipelineSchedulesQuery, querySuccessHandler],
        ]);

        await waitForPromises();

        expect(findSubmitButton().text()).toBe(expectedText);
      },
    );
  });

  describe('Schedule creation', () => {
    it('when creating a schedule the query is not called', () => {
      createComponent();

      expect(querySuccessHandler).not.toHaveBeenCalled();
    });

    it('does not show loading state when creating new schedule', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not show variable security button', () => {
      createComponent();

      expect(findVariableSecurityBtn().exists()).toBe(false);
    });

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

  describe('Schedule editing', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('shows loading state when editing', async () => {
      createComponent(shallowMountExtended, true, [
        [getPipelineSchedulesQuery, querySuccessHandler],
      ]);

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows variable security button', async () => {
      createComponent(shallowMountExtended, true, [
        [getPipelineSchedulesQuery, querySuccessHandler],
      ]);

      await waitForPromises();

      expect(findVariableSecurityBtn().exists()).toBe(true);
    });

    it('does not show variable security button with no present variables', async () => {
      createComponent(shallowMountExtended, true, [
        [getPipelineSchedulesQuery, querySuccessEmptyVarsHandler],
      ]);

      await waitForPromises();

      expect(findVariableSecurityBtn().exists()).toBe(false);
    });

    describe('schedule fetch success', () => {
      it('fetches schedule and sets form data correctly', async () => {
        createComponent(mountExtended, true, [[getPipelineSchedulesQuery, querySuccessHandler]]);

        expect(querySuccessHandler).toHaveBeenCalled();

        await waitForPromises();

        expect(findDescription().element.value).toBe(schedule.description);
        expect(findIntervalComponent().props('initialCronInterval')).toBe(schedule.cron);
        expect(findTimezoneDropdown().props('value')).toBe(schedule.cronTimezone);
        expect(findRefSelector().props('value')).toBe(schedule.ref);
        expect(findVariableRows()).toHaveLength(3);
        expect(findKeyInputs().at(0).element.value).toBe(variables[0].key);
        expect(findKeyInputs().at(1).element.value).toBe(variables[1].key);
        // values are hidden on load when editing a schedule
        expect(findHiddenValueInputs().at(0).element.value).toBe('*****************');
        expect(findHiddenValueInputs().at(1).element.value).toBe('*****************');
        expect(findHiddenValueInputs().at(0).attributes('disabled')).toBe('disabled');
        expect(findHiddenValueInputs().at(1).attributes('disabled')).toBe('disabled');
        // empty placeholder to create a new variable
        expect(findValueInputs()).toHaveLength(1);
      });
    });

    it('schedule fetch failure', async () => {
      createComponent(shallowMountExtended, true, [
        [getPipelineSchedulesQuery, queryFailedHandler],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while trying to fetch the pipeline schedule.',
      });
    });

    it('edit schedule success', async () => {
      createComponent(mountExtended, true, [
        [getPipelineSchedulesQuery, querySuccessHandler],
        [updatePipelineScheduleMutation, updateMutationHandlerSuccess],
      ]);

      await waitForPromises();

      findDescription().element.value = 'Updated schedule';
      findDescription().trigger('change');

      findIntervalComponent().vm.$emit('cronValue', '0 22 16 * *');

      // Ensures variable is sent with destroy property set true
      findRemoveIcons().at(0).vm.$emit('click');

      findSubmitButton().vm.$emit('click');

      await waitForPromises();

      expect(updateMutationHandlerSuccess).toHaveBeenCalledWith({
        input: {
          active: schedule.active,
          cron: '0 22 16 * *',
          cronTimezone: schedule.cronTimezone,
          id: schedule.id,
          ref: schedule.ref,
          description: 'Updated schedule',
          variables: [
            {
              destroy: true,
              id: variables[0].id,
              key: variables[0].key,
              value: variables[0].value,
              variableType: variables[0].variableType,
            },
            {
              destroy: false,
              id: variables[1].id,
              key: variables[1].key,
              value: variables[1].value,
              variableType: variables[1].variableType,
            },
          ],
        },
      });
    });

    it('edit schedule failure', async () => {
      createComponent(shallowMountExtended, true, [
        [getPipelineSchedulesQuery, querySuccessHandler],
        [updatePipelineScheduleMutation, updateMutationHandlerFailed],
      ]);

      await waitForPromises();

      findSubmitButton().vm.$emit('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while updating the pipeline schedule.',
      });
    });

    it('hides/shows variable values', async () => {
      createComponent(mountExtended, true, [[getPipelineSchedulesQuery, querySuccessHandler]]);

      await waitForPromises();

      // shows two hidden values and one placeholder
      expect(findHiddenValueInputs()).toHaveLength(2);
      expect(findValueInputs()).toHaveLength(1);

      findVariableSecurityBtn().vm.$emit('click');

      await nextTick();

      // shows all variable values
      expect(findHiddenValueInputs()).toHaveLength(0);
      expect(findValueInputs()).toHaveLength(3);
    });
  });
});
