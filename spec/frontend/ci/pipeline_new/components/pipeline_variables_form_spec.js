import { GlFormGroup, GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { reportToSentry } from '~/ci/utils';
import ciConfigVariablesQuery from '~/ci/pipeline_new/graphql/queries/ci_config_variables.graphql';
import { VARIABLE_TYPE } from '~/ci/pipeline_new/constants';
import InputsAdoptionBanner from '~/ci/common/pipeline_inputs/inputs_adoption_banner.vue';
import PipelineVariablesForm from '~/ci/pipeline_new/components/pipeline_variables_form.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';
import { createAlert } from '~/alert';

jest.mock('~/alert');
jest.useFakeTimers();

Vue.use(VueApollo);
jest.mock('~/ci/utils');
jest.mock('@gitlab/ui/src/utils', () => ({
  GlBreakpointInstance: {
    getBreakpointSize: jest.fn(),
  },
}));

describe('PipelineVariablesForm', () => {
  let wrapper;
  let mockApollo;
  let mockCiConfigVariables;

  const defaultProps = {
    isMaintainer: true,
    refParam: 'refs/heads/feature',
    settingsLink: 'link/to/settings',
  };

  const defaultProvide = { projectPath: 'group/project' };

  const configVariablesWithOptions = [
    {
      key: 'VAR_WITH_OPTIONS',
      value: 'option1',
      description: 'Variable with options',
      valueOptions: ['option1', 'option2', 'option3'],
    },
    {
      key: 'SIMPLE_VAR',
      value: 'simple-value',
      description: 'Simple variable',
      valueOptions: [],
    },
  ];

  const configVariablesWithMarkdown = [
    {
      key: 'VAR_WITH_MARKDOWN',
      value: 'some-value',
      description: 'Variable with **Markdown** _description_',
    },
    {
      key: 'SIMPLE_VAR',
      value: 'simple-value',
      description: 'Simple variable',
    },
  ];

  const configVariablesWithDuplicateOptions = [
    {
      key: 'VAR_WITH_DUPLICATE_OPTIONS',
      value: 'option1',
      description: 'Variable with duplicate options',
      valueOptions: ['option1', 'option2', 'option3', 'option2', 'option1', 'option3'],
    },
  ];

  const createComponent = async ({ props = {}, configVariables = [] } = {}) => {
    mockCiConfigVariables = jest.fn().mockResolvedValue({
      data: {
        project: {
          ciConfigVariables: configVariables,
        },
      },
    });

    const handlers = [[ciConfigVariablesQuery, mockCiConfigVariables]];
    mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(PipelineVariablesForm, {
      apolloProvider: mockApollo,
      propsData: { ...defaultProps, ...props },
      provide: {
        ...defaultProvide,
      },
    });

    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlFormGroup);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findInputsAdoptionBanner = () => wrapper.findComponent(InputsAdoptionBanner);
  const findVariableRows = () => wrapper.findAllByTestId('ci-variable-row-container');
  const findKeyInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-key-field');
  const findRemoveButton = () => wrapper.findByTestId('remove-ci-variable-button');
  const findRemoveButtonDesktop = () => wrapper.findByTestId('remove-ci-variable-button-desktop');
  const findMarkdown = () => wrapper.findComponent(Markdown);
  const findDropdownForVariable = () =>
    wrapper.findByTestId('pipeline-form-ci-variable-value-dropdown');

  beforeEach(() => {
    mockCiConfigVariables = jest.fn().mockResolvedValue({
      data: {
        project: {
          ciConfigVariables: [],
        },
      },
    });

    jest.clearAllMocks();
  });

  it('displays the inputs adoption banner', async () => {
    await createComponent();

    expect(findInputsAdoptionBanner().exists()).toBe(true);
    expect(findInputsAdoptionBanner().props('featureName')).toBe(
      'pipeline_new_inputs_adoption_banner',
    );
  });

  describe('loading states', () => {
    it('shows loading when ciConfigVariables is null', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findForm().exists()).toBe(false);
    });

    it('hides loading after data is received', async () => {
      await createComponent();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findForm().exists()).toBe(true);
      expect(wrapper.vm.isFetchingCiConfigVariables).toBe(false);
    });

    it('hides loading when polling reaches max time', async () => {
      mockCiConfigVariables = jest.fn().mockResolvedValue({
        data: { project: { ciConfigVariables: null } },
      });

      await createComponent();

      // Simulate max polling timeout
      jest.advanceTimersByTime(10000);
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findForm().exists()).toBe(true);
      expect(wrapper.vm.ciConfigVariables).toEqual([]);
    });
  });

  describe('form initialization', () => {
    it('adds an empty variable row', async () => {
      await createComponent();

      expect(findVariableRows()).toHaveLength(1);
    });

    it('initializes with variables from config', async () => {
      await createComponent({ configVariables: configVariablesWithOptions });

      const keyInputs = findKeyInputs();
      expect(keyInputs.length).toBeGreaterThanOrEqual(1);

      // Check if at least one of the expected variables exists
      const keys = keyInputs.wrappers.map((w) => w.props('value'));
      expect(keys.some((key) => ['VAR_WITH_OPTIONS', 'SIMPLE_VAR'].includes(key))).toBe(true);
    });

    it('initializes with variables from props', async () => {
      await createComponent({
        props: {
          variableParams: { CUSTOM_VAR: 'custom-value' },
        },
      });

      const keyInputs = findKeyInputs();
      expect(keyInputs.length).toBeGreaterThanOrEqual(1);

      // At least the empty row should exist
      const emptyRowExists = keyInputs.wrappers.some((w) => w.props('value') === '');
      expect(emptyRowExists).toBe(true);
    });

    it('renders markdown if variable has description', async () => {
      await createComponent({ configVariables: configVariablesWithMarkdown });

      expect(findMarkdown().exists()).toBe(true);
      expect(findMarkdown().props('markdown')).toBe('Variable with **Markdown** _description_');
    });

    it('does not render anything when description is missing', async () => {
      await createComponent({
        props: {
          variableParams: { CUSTOM_VAR: 'custom-value' },
        },
      });

      expect(findMarkdown().exists()).toBe(false);
    });

    it('removes duplicate options from the dropdown', async () => {
      await createComponent({ configVariables: configVariablesWithDuplicateOptions });

      expect(findDropdownForVariable().props('items')).toEqual([
        { text: 'option1', value: 'option1' },
        { text: 'option2', value: 'option2' },
        { text: 'option3', value: 'option3' },
      ]);
    });
  });

  describe('query configuration', () => {
    it('makes query with correct variables', async () => {
      await createComponent();

      expect(mockCiConfigVariables).toHaveBeenCalledWith({
        fullPath: defaultProvide.projectPath,
        ref: defaultProps.refParam,
        failOnCacheMiss: false,
      });
    });

    it('handles query errors in executeQuery method', async () => {
      const error = new Error('GraphQL error');
      const mockQuery = jest.fn().mockRejectedValue(error);

      await createComponent();
      wrapper.vm.$apollo.query = mockQuery;

      await wrapper.vm.executeQuery(false);

      expect(reportToSentry).toHaveBeenCalledWith('PipelineVariablesForm', error);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'GraphQL error',
      });
      expect(wrapper.vm.ciConfigVariables).toEqual([]);
    });

    it('handles query errors with failOnCacheMiss flag in executeQuery method', async () => {
      const error = new Error('GraphQL error');
      const mockQuery = jest.fn().mockRejectedValue(error);

      await createComponent();
      wrapper.vm.$apollo.query = mockQuery;

      const result = await wrapper.vm.executeQuery(true);

      expect(result).toBe(true);
      expect(reportToSentry).toHaveBeenCalledWith('PipelineVariablesForm', error);
    });

    it('returns false when no ciConfigVariables received', async () => {
      const mockQuery = jest.fn().mockResolvedValue({
        data: { project: { ciConfigVariables: null } },
      });

      await createComponent();
      wrapper.vm.$apollo.query = mockQuery;

      const result = await wrapper.vm.executeQuery(false);

      expect(result).toBe(false);
    });

    it('returns true when ciConfigVariables received', async () => {
      const mockQuery = jest.fn().mockResolvedValue({
        data: { project: { ciConfigVariables: configVariablesWithOptions } },
      });

      await createComponent();
      wrapper.vm.$apollo.query = mockQuery;

      const result = await wrapper.vm.executeQuery(false);

      expect(result).toBe(true);
    });
  });

  describe('polling behavior', () => {
    it('starts manual polling with correct interval', async () => {
      jest.spyOn(global, 'setInterval');
      jest.spyOn(global, 'setTimeout');

      await createComponent();

      wrapper.vm.startManualPolling();

      expect(setInterval).toHaveBeenCalledWith(expect.any(Function), 2000);
      expect(setTimeout).toHaveBeenCalledWith(expect.any(Function), 10000);
    });

    it('executes query immediately when starting manual polling', async () => {
      const executeQuerySpy = jest.spyOn(PipelineVariablesForm.methods, 'executeQuery');

      await createComponent();

      expect(executeQuerySpy).toHaveBeenCalledWith(false);
    });

    it('refetches and updates on ref change', async () => {
      await createComponent();

      const startManualPollingSpy = jest.spyOn(wrapper.vm, 'startManualPolling');

      await wrapper.setProps({ refParam: 'refs/heads/new-feature' });

      expect(startManualPollingSpy).toHaveBeenCalledTimes(1);

      await wrapper.setProps({ refParam: 'refs/heads/new-feature-1' });

      expect(startManualPollingSpy).toHaveBeenCalledTimes(2);
    });

    it('stops polling when data is received', async () => {
      jest.spyOn(global, 'clearInterval');
      jest.spyOn(global, 'clearTimeout');

      mockCiConfigVariables = jest
        .fn()
        .mockResolvedValueOnce({
          data: { project: { ciConfigVariables: null } },
        })
        .mockResolvedValueOnce({
          data: { project: { ciConfigVariables: configVariablesWithOptions } },
        });

      await createComponent();

      jest.advanceTimersByTime(2000);
      await waitForPromises();

      expect(clearInterval).toHaveBeenCalled();
      expect(clearTimeout).toHaveBeenCalled();
    });

    it('clears all timeouts when polling stops due to successful query', async () => {
      jest.spyOn(global, 'clearInterval');
      jest.spyOn(global, 'clearTimeout');

      await createComponent();
      jest.spyOn(wrapper.vm, 'executeQuery').mockResolvedValue(true);

      jest.advanceTimersByTime(2000);
      await waitForPromises();

      expect(clearInterval).toHaveBeenCalled();
      expect(clearTimeout).toHaveBeenCalled();
      expect(wrapper.vm.manualPollInterval).toBe(null);
      expect(wrapper.vm.pollingStartTime).toBe(null);
    });

    it('sets empty array when max poll timeout reached', async () => {
      await createComponent();

      jest.advanceTimersByTime(10000);
      await waitForPromises();

      expect(wrapper.vm.ciConfigVariables).toEqual([]);
    });
  });

  describe('variable rows', () => {
    it('emits variables-updated event when variables change', async () => {
      await createComponent();

      expect(wrapper.emitted('variables-updated')).toHaveLength(1);

      wrapper.vm.$options.watch.variables.handler.call(wrapper.vm, [
        { key: 'TEST_KEY', value: 'test_value', variableType: VARIABLE_TYPE },
      ]);

      expect(wrapper.emitted('variables-updated')).toHaveLength(2);
    });
  });

  describe('variable removal with responsive design', () => {
    beforeEach(async () => {
      await createComponent({
        props: { variableParams: { VAR1: 'value1' } },
      });
    });

    it('uses secondary button category on mobile', () => {
      expect(findRemoveButton().exists()).toBe(true);

      expect(findRemoveButton().props('size')).toBe('medium');
      expect(findRemoveButton().props('icon')).toBe('remove');
      expect(findRemoveButton().props('disabled')).toBe(false);
      expect(findRemoveButton().props('category')).toBe('secondary');

      expect(findRemoveButton().text()).toBe('Remove variable');
    });

    it('uses tertiary button category on desktop', () => {
      expect(findRemoveButtonDesktop().exists()).toBe(true);

      expect(findRemoveButtonDesktop().props('size')).toBe('medium');
      expect(findRemoveButtonDesktop().props('icon')).toBe('remove');
      expect(findRemoveButtonDesktop().props('disabled')).toBe(false);
      expect(findRemoveButtonDesktop().props('category')).toBe('tertiary');

      expect(findRemoveButtonDesktop().attributes('aria-label')).toBe('Remove variable');
    });
  });

  describe('settings link', () => {
    it('passes correct props for maintainers', async () => {
      await createComponent({ props: { isMaintainer: true } });

      expect(wrapper.props('isMaintainer')).toBe(true);
      expect(wrapper.props('settingsLink')).toBe(defaultProps.settingsLink);
    });

    it('passes correct props for non-maintainers', async () => {
      await createComponent({ props: { isMaintainer: false } });

      expect(wrapper.props('isMaintainer')).toBe(false);
    });
  });
});
