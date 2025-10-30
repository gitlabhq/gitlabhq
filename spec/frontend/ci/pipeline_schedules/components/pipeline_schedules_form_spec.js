import { GlForm, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import PipelineSchedulesForm from '~/ci/pipeline_schedules/components/pipeline_schedules_form.vue';
import VariablesForm from '~/ci/common/variables_form.vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';
import createPipelineScheduleMutation from '~/ci/pipeline_schedules/graphql/mutations/create_pipeline_schedule.mutation.graphql';
import updatePipelineScheduleMutation from '~/ci/pipeline_schedules/graphql/mutations/update_pipeline_schedule.mutation.graphql';
import getPipelineVariablesMinimumOverrideRoleQuery from '~/ci/pipeline_variables_minimum_override_role/graphql/queries/get_pipeline_variables_minimum_override_role_project_setting.query.graphql';
import getPipelineSchedulesQuery from '~/ci/pipeline_schedules/graphql/queries/get_pipeline_schedules.query.graphql';
import { timezoneDataFixture } from '../../../vue_shared/components/timezone_dropdown/helpers';
import {
  createScheduleMutationResponse,
  updateScheduleMutationResponse,
  mockSinglePipelineScheduleNode,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.fn().mockReturnValue(''),
  queryToObject: jest.fn().mockReturnValue({ id: '1' }),
}));

const { bindInternalEventDocument } = useMockInternalEventsTracking();
const preventDefault = jest.fn();

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

  const defaultProvide = {
    projectPath: 'gitlab-org/gitlab',
    projectId,
    defaultBranch,
    dailyLimit,
    settingsLink: '',
    schedulesPath: '/root/ci-project/-/pipeline_schedules',
  };

  const querySuccessHandler = jest.fn().mockResolvedValue(mockSinglePipelineScheduleNode);
  const queryFailedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const createMutationHandlerSuccess = jest.fn().mockResolvedValue(createScheduleMutationResponse);
  const createMutationHandlerFailed = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const updateMutationHandlerSuccess = jest.fn().mockResolvedValue(updateScheduleMutationResponse);
  const updateMutationHandlerFailed = jest.fn().mockRejectedValue(new Error('GraphQL error'));

  const createMockApolloProvider = (
    requestHandlers = [
      [getPipelineVariablesMinimumOverrideRoleQuery],
      [createPipelineScheduleMutation, createMutationHandlerSuccess],
    ],
  ) => {
    return createMockApollo(requestHandlers);
  };

  const createComponent = ({
    editing = false,
    requestHandlers,
    canSetPipelineVariables = true,
  } = {}) => {
    wrapper = shallowMountExtended(PipelineSchedulesForm, {
      propsData: {
        timezoneData: timezoneDataFixture,
        editing,
        canSetPipelineVariables,
      },
      provide: {
        ...defaultProvide,
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
  const findPipelineInputsForm = () => wrapper.findComponent(PipelineInputsForm);
  const findPipelineVariables = () => wrapper.findComponent(VariablesForm);

  const emitInputEvents = (updateData) => {
    findPipelineInputsForm().vm.$emit('update-inputs', updateData);
    findPipelineInputsForm().vm.$emit('update-inputs-metadata', {
      totalAvailable: 2,
      totalModified: 2,
      newlyModified: updateData.length,
    });
  };

  describe('Form elements', () => {
    it('displays form', () => {
      createComponent();

      expect(findForm().exists()).toBe(true);
    });

    it('displays the description input', () => {
      createComponent();

      expect(findDescription().exists()).toBe(true);
    });

    it('displays the interval pattern component', () => {
      createComponent();

      const intervalPattern = findIntervalComponent();

      expect(intervalPattern.exists()).toBe(true);
      expect(intervalPattern.props()).toMatchObject({
        initialCronInterval: cron,
        dailyLimit,
        sendNativeErrors: false,
      });
    });

    it('displays the Timezone dropdown', () => {
      createComponent();

      const timezoneDropdown = findTimezoneDropdown();

      expect(timezoneDropdown.exists()).toBe(true);
      expect(timezoneDropdown.props()).toMatchObject({
        value: '',
        name: 'schedule-timezone',
        timezoneData: timezoneDataFixture,
      });
    });

    it('displays the branch/tag selector', () => {
      createComponent();

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

    it('displays inputs form', () => {
      createComponent();

      expect(findPipelineInputsForm().exists()).toBe(true);
      expect(findPipelineInputsForm().props()).toMatchObject({
        queryRef: 'main',
        savedInputs: [],
        emptySelectionText: 'Select inputs to create a new scheduled pipeline.',
      });
    });

    it('displays variable list when the user has permissions', () => {
      createComponent();

      expect(findPipelineVariables().exists()).toBe(true);
      expect(findPipelineVariables().props()).toMatchObject({
        initialVariables: [],
        editing: false,
        userCalloutsFeatureName: 'pipeline_new_inputs_adoption_banner',
      });
    });

    it('does not display variable list when the user has no permissions', () => {
      createComponent({
        canSetPipelineVariables: false,
      });

      expect(findPipelineVariables().exists()).toBe(false);
    });

    it('displays the submit and cancel buttons', () => {
      createComponent();

      expect(findSubmitButton().exists()).toBe(true);
      expect(findCancelButton().exists()).toBe(true);
      expect(findCancelButton().attributes('href')).toBe('/root/ci-project/-/pipeline_schedules');
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
        createComponent({
          editing,
          requestHandlers: [[getPipelineSchedulesQuery, querySuccessHandler]],
        });

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

    it('displays empty variable list', () => {
      createComponent();

      expect(findPipelineVariables().props('initialVariables')).toEqual([]);
      expect(findPipelineVariables().props('editing')).toEqual(false);
    });

    it('tracks the modified inputs', async () => {
      createComponent();

      findDescription().vm.$emit('input', 'My schedule');

      findTimezoneDropdown().vm.$emit('input', {
        formattedTimezone: '[UTC-4] Eastern Time (US & Canada)',
        identifier: 'America/New_York',
      });

      findIntervalComponent().vm.$emit('cronValue', '0 16 * * *');

      emitInputEvents([{ name: 'input1', value: 'value1' }]);

      findForm().vm.$emit('submit', { preventDefault });
      await waitForPromises();

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).toHaveBeenCalledWith(
        'modify_inputs_on_pipeline_schedule_page',
        {
          label: 'new_pipeline_schedule',
          property: 'form_submission',
          value: 1,
          total_inputs: 2,
          total_modified: 2,
        },
        undefined,
      );
    });

    it('creates pipeline schedule successfully', async () => {
      createComponent();

      const updatedInputs = [
        { name: 'input1', value: 'value1' },
        { name: 'input2', value: 'value2' },
      ];
      const updatedVariables = [
        {
          key: 'test_var_2',
          value: 'value_2',
          variableType: 'ENV_VAR',
        },
      ];

      findDescription().vm.$emit('input', 'My schedule');

      findTimezoneDropdown().vm.$emit('input', {
        formattedTimezone: '[UTC-4] Eastern Time (US & Canada)',
        identifier: 'America/New_York',
      });

      findIntervalComponent().vm.$emit('cronValue', '0 16 * * *');

      findPipelineVariables().vm.$emit('update-variables', updatedVariables);
      emitInputEvents(updatedInputs);

      findForm().vm.$emit('submit', { preventDefault });
      await waitForPromises();

      expect(createMutationHandlerSuccess).toHaveBeenCalledWith({
        input: {
          active: true,
          cron: '0 16 * * *',
          cronTimezone: 'America/New_York',
          description: 'My schedule',
          projectPath: 'gitlab-org/gitlab',
          ref: 'main',
          variables: updatedVariables,
          inputs: updatedInputs,
        },
      });
      expect(visitUrl).toHaveBeenCalledWith('/root/ci-project/-/pipeline_schedules');
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('shows error for failed pipeline schedule creation', async () => {
      createComponent({
        requestHandlers: [[createPipelineScheduleMutation, createMutationHandlerFailed]],
      });
      findForm().vm.$emit('submit', { preventDefault });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while creating the pipeline schedule.',
      });
    });

    it('does not track the modified inputs for failed pipeline schedule creation', async () => {
      createComponent({
        requestHandlers: [[createPipelineScheduleMutation, createMutationHandlerFailed]],
      });
      findForm().vm.$emit('submit', { preventDefault });

      await waitForPromises();

      emitInputEvents([{ name: 'input1', value: 'value1' }]);

      findForm().vm.$emit('submit', { preventDefault });
      await waitForPromises();

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).not.toHaveBeenCalled();
    });
  });

  describe('Schedule editing', () => {
    it('shows loading state when editing', async () => {
      createComponent({
        editing: true,
        requestHandlers: [[getPipelineSchedulesQuery, querySuccessHandler]],
      });

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('provides variables to the variable list', async () => {
      createComponent({
        editing: true,
        requestHandlers: [[getPipelineSchedulesQuery, querySuccessHandler]],
      });
      await waitForPromises();

      expect(findPipelineVariables().props('editing')).toBe(true);
      expect(findPipelineVariables().props('initialVariables')).toHaveLength(variables.length);
    });

    it('fetches schedule and sets form data correctly', async () => {
      createComponent({
        editing: true,
        requestHandlers: [[getPipelineSchedulesQuery, querySuccessHandler]],
      });

      expect(querySuccessHandler).toHaveBeenCalled();

      await waitForPromises();

      expect(findDescription().props('value')).toBe(schedule.description);
      expect(findIntervalComponent().props('initialCronInterval')).toBe(schedule.cron);
      expect(findTimezoneDropdown().props('value')).toBe(schedule.cronTimezone);
      expect(findRefSelector().props('value')).toBe(schedule.ref);
      expect(findPipelineVariables().props('initialVariables')).toHaveLength(2);
      expect(findPipelineVariables().props('initialVariables')[0].key).toBe(variables[0].key);
      expect(findPipelineVariables().props('initialVariables')[1].key).toBe(variables[1].key);
    });

    it('schedule fetch failure', async () => {
      createComponent({
        editing: true,
        requestHandlers: [[getPipelineSchedulesQuery, queryFailedHandler]],
      });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while trying to fetch the pipeline schedule.',
      });
    });

    it('tracks the modified inputs', async () => {
      createComponent({
        editing: true,
        requestHandlers: [
          [getPipelineSchedulesQuery, querySuccessHandler],
          [updatePipelineScheduleMutation, updateMutationHandlerSuccess],
        ],
      });

      await waitForPromises();

      emitInputEvents([{ name: 'input1', value: 'value1' }]);

      findForm().vm.$emit('submit', { preventDefault });
      await waitForPromises();

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).toHaveBeenCalledWith(
        'modify_inputs_on_pipeline_schedule_page',
        {
          label: 'edit_pipeline_schedule',
          property: 'form_submission',
          value: 1,
          total_inputs: 2,
          total_modified: 2,
        },
        undefined,
      );
    });

    it('edit schedule success', async () => {
      const updatedInputs = [
        { name: 'input1', value: 'value1' },
        { name: 'input2', value: 'value2' },
      ];
      const updatedVariables = [
        {
          id: variables[0].id,
          key: variables[0].key,
          value: variables[0].value,
          variableType: variables[0].variableType,
          destroy: true,
        },
        {
          id: variables[1].id,
          key: variables[1].key,
          value: variables[1].value,
          variableType: variables[1].variableType,
          destroy: false,
        },
      ];

      createComponent({
        editing: true,
        requestHandlers: [
          [getPipelineSchedulesQuery, querySuccessHandler],
          [updatePipelineScheduleMutation, updateMutationHandlerSuccess],
        ],
      });

      await waitForPromises();

      findDescription().vm.$emit('input', 'Updated schedule');

      findIntervalComponent().vm.$emit('cronValue', '0 22 16 * *');

      // Ensures variable is sent with destroy property set true
      findPipelineVariables().vm.$emit('update-variables', updatedVariables);
      emitInputEvents(updatedInputs);

      findForm().vm.$emit('submit', { preventDefault });

      await waitForPromises();

      expect(updateMutationHandlerSuccess).toHaveBeenCalledWith({
        input: {
          active: schedule.active,
          cron: '0 22 16 * *',
          cronTimezone: schedule.cronTimezone,
          id: schedule.id,
          ref: schedule.ref,
          description: 'Updated schedule',
          variables: updatedVariables,
          inputs: updatedInputs,
        },
      });
    });

    it('edit schedule failure', async () => {
      createComponent({
        editing: true,
        requestHandlers: [
          [getPipelineSchedulesQuery, querySuccessHandler],
          [updatePipelineScheduleMutation, updateMutationHandlerFailed],
        ],
      });

      await waitForPromises();

      findForm().vm.$emit('submit', { preventDefault });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while updating the pipeline schedule.',
      });
    });

    it('does not track the modified inputs for failed pipeline schedule editing', async () => {
      createComponent({
        editing: true,
        requestHandlers: [
          [getPipelineSchedulesQuery, querySuccessHandler],
          [updatePipelineScheduleMutation, updateMutationHandlerFailed],
        ],
      });
      await waitForPromises();
      findForm().vm.$emit('submit', { preventDefault });

      emitInputEvents([{ name: 'input1', value: 'value1' }]);

      findForm().vm.$emit('submit', { preventDefault });
      await waitForPromises();

      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      expect(trackEventSpy).not.toHaveBeenCalled();
    });
  });
});
