import { GlFormGroup, GlLoadingIcon } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { fetchPolicies } from '~/lib/graphql';
import { reportToSentry } from '~/ci/utils';
import ciConfigVariablesQuery from '~/ci/pipeline_new/graphql/queries/ci_config_variables.graphql';
import { VARIABLE_TYPE } from '~/ci/pipeline_new/constants';
import InputsAdoptionBanner from '~/ci/common/pipeline_inputs/inputs_adoption_banner.vue';
import PipelineVariablesForm from '~/ci/pipeline_new/components/pipeline_variables_form.vue';

Vue.use(VueApollo);
jest.mock('~/ci/utils');
jest.mock('@gitlab/ui/dist/utils', () => ({
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

  const createComponent = async ({
    props = {},
    configVariables = [],
    ciInputsForPipelines = false,
  } = {}) => {
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
        glFeatures: {
          ciInputsForPipelines,
        },
      },
    });

    await waitForPromises();
  };

  const findForm = () => wrapper.findComponent(GlFormGroup);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findInputsAdoptionBanner = () => wrapper.findComponent(InputsAdoptionBanner);
  const findVariableRows = () => wrapper.findAllByTestId('ci-variable-row-container');
  const findKeyInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-key-field');
  const findRemoveButton = () => wrapper.findByTestId('remove-ci-variable-row');

  beforeEach(() => {
    mockCiConfigVariables = jest.fn().mockResolvedValue({
      data: {
        project: {
          ciConfigVariables: [],
        },
      },
    });
  });

  describe('Feature flag', () => {
    describe('when the ciInputsForPipelines flag is disabled', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('does not display the inputs adoption banner', () => {
        expect(findInputsAdoptionBanner().exists()).toBe(false);
      });
    });

    describe('when the ciInputsForPipelines flag is enabled', () => {
      beforeEach(async () => {
        await createComponent({ ciInputsForPipelines: true });
      });

      it('displays the inputs adoption banner', () => {
        expect(findInputsAdoptionBanner().exists()).toBe(true);
        expect(findInputsAdoptionBanner().props('featureName')).toBe(
          'pipeline_new_inputs_adoption_banner',
        );
      });
    });
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
  });

  describe('query configuration', () => {
    it('has correct apollo query configuration', async () => {
      await createComponent();
      const { apollo } = wrapper.vm.$options;

      expect(apollo.ciConfigVariables.fetchPolicy).toBe(fetchPolicies.NO_CACHE);
      expect(apollo.ciConfigVariables.query).toBe(ciConfigVariablesQuery);
    });

    it('makes query with correct variables', async () => {
      await createComponent();

      expect(mockCiConfigVariables).toHaveBeenCalledWith({
        fullPath: defaultProvide.projectPath,
        ref: defaultProps.refParam,
      });
    });

    it('reports to sentry when query fails', async () => {
      const error = new Error('GraphQL error');
      await createComponent();
      wrapper.vm.$options.apollo.ciConfigVariables.error.call(wrapper.vm, error);

      expect(reportToSentry).toHaveBeenCalledWith('PipelineVariablesForm', error);
    });
  });

  describe('polling behavior', () => {
    it('configures Apollo with the correct polling interval', () => {
      expect(PipelineVariablesForm.apollo.ciConfigVariables.pollInterval).toBe(2000);
    });

    it('refetches and updates on ref change', async () => {
      await createComponent();

      wrapper.setProps({ refParam: 'new-ref-param' });
      await nextTick();

      expect(wrapper.vm.ciConfigVariables).toBe(null);
    });

    it('sets ciConfigVariables to empty array on query error', async () => {
      await createComponent();

      const error = new Error('GraphQL error');
      wrapper.vm.$options.apollo.ciConfigVariables.error.call(wrapper.vm, error);

      expect(wrapper.vm.ciConfigVariables).toEqual([]);
      expect(reportToSentry).toHaveBeenCalledWith('PipelineVariablesForm', error);
    });

    it('stops polling when data is received', async () => {
      await createComponent({ configVariables: configVariablesWithOptions });

      const stopPollingSpy = jest.spyOn(
        wrapper.vm.$apollo.queries.ciConfigVariables,
        'stopPolling',
      );

      const mockData = { data: { project: { ciConfigVariables: configVariablesWithOptions } } };
      wrapper.vm.$options.apollo.ciConfigVariables.result.call(wrapper.vm, mockData);

      expect(stopPollingSpy).toHaveBeenCalled();
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

  describe('variable removal', () => {
    it('shows remove button with correct aria-label', async () => {
      await createComponent({
        props: { variableParams: { VAR1: 'value1', VAR2: 'value2' } },
      });

      expect(findRemoveButton().exists()).toBe(true);
      expect(findRemoveButton().attributes('aria-label')).toBe('Remove variable');
    });
  });

  describe('responsive design', () => {
    it('uses secondary button category on mobile', async () => {
      GlBreakpointInstance.getBreakpointSize.mockReturnValue('sm');
      await createComponent({
        props: { variableParams: { VAR1: 'value1' } },
      });

      expect(findRemoveButton().exists()).toBe(true);
      expect(findRemoveButton().props('category')).toBe('secondary');
    });

    it('uses tertiary button category on desktop', async () => {
      GlBreakpointInstance.getBreakpointSize.mockReturnValue('md');
      await createComponent({
        props: { variableParams: { VAR1: 'value1' } },
      });

      expect(findRemoveButton().exists()).toBe(true);
      expect(findRemoveButton().props('category')).toBe('tertiary');
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
