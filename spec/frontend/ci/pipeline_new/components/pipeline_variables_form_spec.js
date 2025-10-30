import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { reportToSentry } from '~/ci/utils';
import ciConfigVariablesQuery from '~/ci/pipeline_new/graphql/queries/ci_config_variables.graphql';
import { CI_VARIABLE_TYPE_ENV_VAR } from '~/ci/pipeline_new/constants';
import PipelineVariablesForm from '~/ci/pipeline_new/components/pipeline_variables_form.vue';
import { createAlert } from '~/alert';
import VariablesForm from '~/ci/common/variables_form.vue';

jest.mock('~/alert');
jest.useFakeTimers();

Vue.use(VueApollo);
jest.mock('~/ci/utils');

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

  const configWithMixedDescriptions = [
    { key: 'WITH_DESC', value: 'val1', description: 'Has description' },
    { key: 'NO_DESC', value: 'val2', description: null },
    { key: 'ALSO_NO_DESC', value: 'val3' },
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
      provide: defaultProvide,
    });

    await waitForPromises();
  };

  const findVariablesForm = () => wrapper.findComponent(VariablesForm);

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

  describe('VariablesForm integration', () => {
    it('passes correct props to VariablesForm', async () => {
      await createComponent();

      expect(findVariablesForm().props()).toMatchObject({
        isLoading: false,
        userCalloutsFeatureName: 'pipeline_new_inputs_adoption_banner',
      });
    });

    it('passes initial variables from config to form', async () => {
      await createComponent({ configVariables: configVariablesWithOptions });

      const initialVariables = findVariablesForm().props('initialVariables');
      const keys = initialVariables.map((v) => v.key);

      expect(keys).toContain('VAR_WITH_OPTIONS');
      expect(keys).toContain('SIMPLE_VAR');
    });

    it('passes variables from variableParams prop to form', async () => {
      await createComponent({
        props: {
          variableParams: { CUSTOM_VAR: 'custom-value' },
        },
      });

      const initialVariables = findVariablesForm().props('initialVariables');
      const customVar = initialVariables.find((v) => v.key === 'CUSTOM_VAR');

      expect(customVar).toBeDefined();
      expect(customVar.value).toBe('custom-value');
    });

    it('passes variables from fileParams prop to form', async () => {
      await createComponent({
        props: {
          fileParams: { FILE_VAR: 'file-content' },
        },
      });

      const initialVariables = findVariablesForm().props('initialVariables');
      const fileVar = initialVariables.find((v) => v.key === 'FILE_VAR');

      expect(fileVar).toBeDefined();
      expect(fileVar.value).toBe('file-content');
      expect(fileVar.variableType).toBe('FILE');
    });

    it('preserves variable descriptions', async () => {
      await createComponent({ configVariables: configVariablesWithMarkdown });

      const initialVariables = findVariablesForm().props('initialVariables');
      const varWithMarkdown = initialVariables.find((v) => v.key === 'VAR_WITH_MARKDOWN');

      expect(varWithMarkdown.description).toBe('Variable with **Markdown** _description_');
    });

    it('only includes variables with descriptions from config', async () => {
      await createComponent({ configVariables: configWithMixedDescriptions });

      const initialVariables = findVariablesForm().props('initialVariables');
      const keys = initialVariables.map((v) => v.key);

      expect(keys).toContain('WITH_DESC');
      expect(keys).not.toContain('NO_DESC');
      expect(keys).not.toContain('ALSO_NO_DESC');
    });

    it('emits variables-updated when form updates', async () => {
      await createComponent();

      const updatedVariables = [
        {
          key: 'TEST_KEY',
          value: 'test_value',
          variableType: CI_VARIABLE_TYPE_ENV_VAR,
          destroy: false,
        },
      ];

      findVariablesForm().vm.$emit('update-variables', updatedVariables);
      await nextTick();

      expect(wrapper.emitted('variables-updated')).toHaveLength(1);
      expect(wrapper.emitted('variables-updated')[0][0]).toEqual(
        expect.arrayContaining([expect.objectContaining({ key: 'TEST_KEY', value: 'test_value' })]),
      );
    });
  });

  describe('Loading states', () => {
    it('shows loading while fetching config variables', () => {
      createComponent();

      expect(findVariablesForm().props('isLoading')).toBe(true);
    });

    it('hides loading after data is received', async () => {
      await createComponent();

      expect(findVariablesForm().props('isLoading')).toBe(false);
    });

    it('hides loading when polling reaches max time', async () => {
      mockCiConfigVariables = jest.fn().mockResolvedValue({
        data: { project: { ciConfigVariables: null } },
      });

      await createComponent();

      // Simulate max polling timeout
      jest.advanceTimersByTime(10000);
      await nextTick();

      expect(findVariablesForm().props('isLoading')).toBe(false);
      expect(findVariablesForm().props('initialVariables')).toEqual([]);
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

  describe('Description slot', () => {
    it('renders settings link for maintainers', async () => {
      await createComponent({ props: { isMaintainer: true } });

      expect(wrapper.props('isMaintainer')).toBe(true);
      expect(wrapper.props('settingsLink')).toBe(defaultProps.settingsLink);
    });

    it('passes isMaintainer prop correctly for non-maintainers', async () => {
      await createComponent({ props: { isMaintainer: false } });

      expect(wrapper.props('isMaintainer')).toBe(false);
    });
  });
});
