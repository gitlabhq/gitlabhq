import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import CrudComponent from '~/vue_shared/components/crud_component.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import InputsTableSkeletonLoader from '~/ci/common/pipeline_inputs/pipeline_inputs_table/inputs_table_skeleton_loader.vue';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import PipelineInputsTable from '~/ci/common/pipeline_inputs/pipeline_inputs_table/pipeline_inputs_table.vue';
import PipelineInputsPreviewDrawer from '~/ci/common/pipeline_inputs/pipeline_inputs_preview_drawer.vue';
import getPipelineInputsQuery from '~/ci/common/pipeline_inputs/graphql/queries/pipeline_creation_inputs.query.graphql';
/** mock data to be replaced with fixtures - https://gitlab.com/gitlab-org/gitlab/-/issues/525243 */
import {
  mockPipelineInputsResponse,
  mockEmptyInputsResponse,
  mockPipelineInputsErrorResponse,
  mockPipelineInputsWithRules,
  mockPipelineInputsWithComplexRules,
} from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

const defaultProps = {
  queryRef: 'main',
  emptySelectionText: 'Select inputs to create a new pipeline.',
};
const defaultProvide = {
  projectPath: '/root/project',
};

const expectedInputs = [
  {
    name: 'deploy_environment',
    description: 'Specify deployment environment',
    default: 'staging',
    value: 'staging',
    type: 'text',
    required: false,
    options: ['staging', 'production'],
    regex: '^(staging|production)$',
    rules: null,
    isSelected: false,
    hasRules: false,
  },
  {
    name: 'api_token',
    description: 'API token for deployment',
    default: '',
    value: '',
    type: 'text',
    required: true,
    options: [],
    regex: null,
    rules: null,
    isSelected: false,
    hasRules: false,
  },
  {
    name: 'tags',
    description: 'Tags for deployment',
    default: '',
    value: '',
    type: 'ARRAY',
    required: false,
    options: [],
    regex: null,
    rules: null,
    isSelected: false,
    hasRules: false,
  },
];

describe('PipelineInputsForm', () => {
  let wrapper;
  let pipelineInputsHandler;

  const createComponent = async ({ props = {}, provide = {} } = {}) => {
    const handlers = [[getPipelineInputsQuery, pipelineInputsHandler]];
    // Use cacheOptions, not resolvers!
    const cacheOptions = {
      typePolicies: {
        CiPipelineCreationInput: {
          fields: {
            rules: {
              read(existing) {
                // Return existing value or null
                return existing || null;
              },
            },
          },
        },
      },
    };

    const mockApollo = createMockApollo(handlers, {}, cacheOptions); // Note: empty resolvers, cacheOptions as 3rd param

    wrapper = shallowMountExtended(PipelineInputsForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      apolloProvider: mockApollo,
      stubs: {
        CrudComponent,
      },
    });
    await waitForPromises();
  };

  const findSkeletonLoader = () => wrapper.findComponent(InputsTableSkeletonLoader);
  const findInputsTable = () => wrapper.findComponent(PipelineInputsTable);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findEmptyState = () => wrapper.findByTestId('no-inputs-empty-state');
  const findEmptySelectionState = () => wrapper.findByTestId('empty-selection-state');
  const findInputsSelector = () => wrapper.findComponent(GlCollapsibleListbox);
  const findPreviewButton = () => wrapper.findComponent(GlButton);
  const findPreviewDrawer = () => wrapper.findComponent(PipelineInputsPreviewDrawer);
  const findHelpPageLink = () => wrapper.findComponent(HelpPageLink);

  const getTableInputs = () => findInputsTable().props('inputs');
  const getInputByName = (name) => getTableInputs().find((i) => i.name === name);

  const selectInputs = async (inputs = ['deploy_environment', 'api_token', 'tags']) => {
    findInputsSelector().vm.$emit('select', inputs);
    await nextTick();
  };

  describe('mounted', () => {
    beforeEach(() => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      createComponent();
    });

    it('sets the initial props for crud component', () => {
      expect(findCrudComponent().exists()).toBe(true);
      expect(findCrudComponent().props()).toMatchObject({
        description:
          'Specify the input values to use in this pipeline. Any inputs left unselected will use their default values.',
        title: 'Inputs',
      });
    });

    it('renders a loading state', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('GraphQL query', () => {
    describe('with inputs', () => {
      beforeEach(async () => {
        pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
        await createComponent();
      });

      it('renders input selector listbox with correct props', () => {
        expect(findInputsSelector().props()).toMatchObject({
          toggleText: 'Select inputs',
          headerText: 'Inputs',
          searchPlaceholder: 'Search input name',
          resetButtonLabel: 'Clear',
        });
      });

      it('provides available items to the listbox', () => {
        expect(findInputsSelector().props('items')).toEqual([
          { text: 'deploy_environment', value: 'deploy_environment' },
          { text: 'api_token', value: 'api_token' },
          { text: 'tags', value: 'tags' },
        ]);
      });

      describe('when no inputs are selected', () => {
        it('does not render a table', () => {
          expect(findInputsTable().exists()).toBe(false);
        });

        it('renders an empty state message', () => {
          expect(findEmptySelectionState().text()).toBe('Select inputs to create a new pipeline.');
        });

        it('renders an empty state illustration', () => {
          expect(findEmptySelectionState().find('img').exists()).toBe(true);
          expect(findEmptySelectionState().find('img').attributes('alt')).toBe(
            'Pipeline inputs empty state image',
          );
        });
      });

      describe('input name search functionality', () => {
        it('filters listbox items based on search term', async () => {
          findInputsSelector().vm.$emit('search', 'api');
          await nextTick();

          expect(findInputsSelector().props('items')).toEqual([
            { text: 'api_token', value: 'api_token' },
          ]);

          findInputsSelector().vm.$emit('search', 'deploy');
          await nextTick();

          expect(findInputsSelector().props('items')).toEqual([
            { text: 'deploy_environment', value: 'deploy_environment' },
          ]);
        });

        it('shows all items when search is cleared', async () => {
          findInputsSelector().vm.$emit('search', 'api');
          await nextTick();
          expect(findInputsSelector().props('items')).toEqual([
            { text: 'api_token', value: 'api_token' },
          ]);

          findInputsSelector().vm.$emit('search', '');
          await nextTick();
          expect(findInputsSelector().props('items')).toEqual([
            { text: 'deploy_environment', value: 'deploy_environment' },
            { text: 'api_token', value: 'api_token' },
            { text: 'tags', value: 'tags' },
          ]);
        });
      });

      describe('input selection', () => {
        beforeEach(() => {
          selectInputs();
        });

        it('does not render an empty state message', () => {
          expect(findEmptySelectionState().exists()).toBe(false);
        });

        it('renders a table when inputs are available', () => {
          expect(findInputsTable().exists()).toBe(true);
        });

        it('adds a group for selected inputs in the listbox', () => {
          expect(findInputsSelector().props('items')).toEqual([
            {
              text: 'Selected',
              options: [
                { text: 'deploy_environment', value: 'deploy_environment' },
                { text: 'api_token', value: 'api_token' },
                { text: 'tags', value: 'tags' },
              ],
            },
          ]);
        });

        it('sends the correct props to the table', () => {
          const updatedSelection = [
            { ...expectedInputs[0], isSelected: true },
            { ...expectedInputs[1], isSelected: true },
            { ...expectedInputs[2], isSelected: true },
          ];
          expect(getTableInputs()).toEqual(updatedSelection);
        });

        it('removes isSelected property when deselected', async () => {
          await selectInputs(['api_token', 'tags']);
          const updatedSelection = [
            { ...expectedInputs[0], isSelected: false },
            { ...expectedInputs[1], isSelected: true },
            { ...expectedInputs[2], isSelected: true },
          ];
          expect(getTableInputs()).toEqual(updatedSelection);
        });

        it('updates a group for selected inputs in the listbox on change', async () => {
          await selectInputs(['api_token', 'tags']);
          expect(findInputsSelector().props('items')).toEqual([
            {
              text: 'Selected',
              options: [
                { text: 'api_token', value: 'api_token' },
                { text: 'tags', value: 'tags' },
              ],
            },
            {
              textSrOnly: true,
              text: 'Available',
              options: [{ text: 'deploy_environment', value: 'deploy_environment' }],
            },
          ]);
        });

        it('clears selection on clear button click', async () => {
          findInputsSelector().vm.$emit('reset');
          await nextTick();

          expect(findInputsTable().exists()).toBe(false);
          expect(findEmptySelectionState().exists()).toBe(true);
        });

        it('selects all inputs on select all button click', async () => {
          findInputsSelector().vm.$emit('select-all');
          await nextTick();

          const updatedSelection = [
            { ...expectedInputs[0], isSelected: true },
            { ...expectedInputs[1], isSelected: true },
            { ...expectedInputs[2], isSelected: true },
          ];
          expect(getTableInputs()).toEqual(updatedSelection);
        });

        it('selects only filtered inputs when search is active', async () => {
          findInputsSelector().vm.$emit('search', 'api');
          await nextTick();

          findInputsSelector().vm.$emit('select-all');
          await nextTick();

          const apiTokenInput = getTableInputs().find((i) => i.name === 'api_token');
          const otherInputs = getTableInputs().filter((i) => i.name !== 'api_token');

          expect(apiTokenInput.isSelected).toBe(true);
          expect(otherInputs.every((i) => !i.isSelected)).toBe(true);
        });
      });

      describe('inputs preview', () => {
        it('renders preview button', () => {
          expect(findPreviewButton().exists()).toBe(true);
        });

        it('opens drawer when preview button is clicked', async () => {
          expect(findPreviewDrawer().props('open')).toBe(false);

          await findPreviewButton().vm.$emit('click');

          expect(findPreviewDrawer().props('open')).toBe(true);
        });

        it('passes inputs to drawer', () => {
          expect(findPreviewDrawer().props('inputs')).toEqual(expectedInputs);
        });

        it('closes drawer when close event is emitted', async () => {
          await findPreviewButton().vm.$emit('click');
          expect(findPreviewDrawer().props('open')).toBe(true);

          await findPreviewDrawer().vm.$emit('close');
          expect(findPreviewDrawer().props('open')).toBe(false);
        });
      });
    });

    describe('with no inputs', () => {
      beforeEach(async () => {
        pipelineInputsHandler = jest.fn().mockResolvedValue(mockEmptyInputsResponse);
        await createComponent();
      });

      it('does not render the input selector listbox', () => {
        expect(findInputsSelector().exists()).toBe(false);
      });

      it('does not render the inputs preview button', () => {
        expect(findPreviewButton().exists()).toBe(false);
      });

      it('does not render a table', () => {
        expect(findInputsTable().exists()).toBe(false);
      });

      it('displays the empty state message', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findEmptyState().text()).toContain('There are no inputs for this configuration.');
      });

      it('displays the help page link', () => {
        expect(findHelpPageLink().exists()).toBe(true);
        expect(findHelpPageLink().props('href')).toBe('ci/inputs/_index.md');
        expect(findHelpPageLink().text()).toBe('How do I use inputs?');
      });

      it('does not display the empty selection state message', () => {
        expect(findEmptySelectionState().exists()).toBe(false);
      });
    });

    describe('with empty ref (error case)', () => {
      it('handles GraphQL error', async () => {
        pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsErrorResponse);
        await createComponent();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'ref can only be an existing branch or tag',
        });
      });

      it('handles generic error', async () => {
        pipelineInputsHandler = jest.fn().mockRejectedValue('Error');
        await createComponent();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem fetching the pipeline inputs. Please try again.',
        });
      });
    });

    describe('when projectPath is not provided', () => {
      beforeEach(async () => {
        pipelineInputsHandler = jest.fn();
        await createComponent({ provide: { projectPath: '' } });
      });

      it('does not execute the query', () => {
        expect(pipelineInputsHandler).not.toHaveBeenCalled();
        expect(findEmptyState().exists()).toBe(true);
      });
    });
  });

  describe('when preselectAllInputs is true', () => {
    beforeEach(async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent({ props: { preselectAllInputs: true } });
    });

    it('preselects all inputs', () => {
      const updatedSelection = [
        { ...expectedInputs[0], isSelected: true },
        { ...expectedInputs[1], isSelected: true },
        { ...expectedInputs[2], isSelected: true },
      ];
      expect(getTableInputs()).toEqual(updatedSelection);
    });
  });

  describe('savedInputs prop', () => {
    beforeEach(async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      const savedInputs = [{ name: 'deploy_environment', value: 'saved-value' }];
      await createComponent({ props: { savedInputs } });
    });

    it('overwrites default values if saved input values are provided', () => {
      const updatedInput = findInputsTable()
        .props('inputs')
        .find((i) => i.name === 'deploy_environment');

      expect(updatedInput.default).toBe('staging');
      expect(updatedInput.savedValue).toBe('saved-value');
      expect(updatedInput.value).toBe('saved-value');
    });

    it('preselects saved inputs', () => {
      const updatedSelection = [
        { ...expectedInputs[0], isSelected: true, value: 'saved-value', savedValue: 'saved-value' },
        { ...expectedInputs[1], isSelected: false },
        { ...expectedInputs[2], isSelected: false },
      ];
      expect(getTableInputs()).toEqual(updatedSelection);
    });
  });

  describe('input update event handling', () => {
    it('processes and emits update events from the table component', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();

      // Emits an event on inputs select
      expect(wrapper.emitted()['update-inputs']).toHaveLength(1);

      const updatedInput = { ...expectedInputs[0], value: 'updated-value', isSelected: true };
      findInputsTable().vm.$emit('update', updatedInput);

      expect(wrapper.emitted()['update-inputs']).toHaveLength(2);

      const expectedEmittedValue = [
        { name: 'deploy_environment', value: 'updated-value' },
        { name: 'api_token', value: '' },
        { name: 'tags', value: '' },
      ];

      expect(wrapper.emitted('update-inputs')[1][0]).toEqual(expectedEmittedValue);
    });

    it('only emits modified inputs when emitModifiedOnly is true', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent({ props: { emitModifiedOnly: true } });
      await selectInputs();

      const inputs = getTableInputs();
      const totalInputsCount = inputs.length;
      const inputToModify = { ...inputs[0], value: 'modified-value', isSelected: true };

      findInputsTable().vm.$emit('update', inputToModify);

      const emittedNameValuePairs = wrapper.emitted('update-inputs')[1][0];

      expect(emittedNameValuePairs).toHaveLength(1);
      expect(emittedNameValuePairs.length).toBeLessThan(totalInputsCount);
    });

    it('when saved input is unselected restores value to default and emits destroy property', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      const savedInputs = [{ name: 'deploy_environment', value: 'saved-value' }];
      await createComponent({ props: { savedInputs } });

      await selectInputs([]);

      const expectedEmittedValue = [
        { name: 'deploy_environment', value: 'staging', destroy: true },
      ];

      expect(wrapper.emitted('update-inputs')[0][0]).toEqual(expectedEmittedValue);
    });

    it('converts string values to arrays for ARRAY type inputs', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();

      // Get the array input from the current inputs prop of the table
      const arrayInput = getTableInputs().find((input) => input.type === 'ARRAY');

      const updatedInput = {
        ...arrayInput,
        value: '[1,2,3]',
      };

      findInputsTable().vm.$emit('update', updatedInput);

      // Check that the emitted value contains the converted array
      const emittedValues = wrapper.emitted('update-inputs')[1][0];
      const emittedArrayValue = emittedValues.find((item) => item.name === 'tags').value;

      expect(Array.isArray(emittedArrayValue)).toBe(true);
      expect(emittedArrayValue).toEqual([1, 2, 3]);
    });

    it('converts complex object arrays correctly', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();

      const arrayInput = getTableInputs().find((input) => input.type === 'ARRAY');

      const updatedInput = {
        ...arrayInput,
        value: '[{"key": "value"}, {"another": "object"}]',
      };

      findInputsTable().vm.$emit('update', updatedInput);

      const emittedValues = wrapper.emitted('update-inputs')[1][0];
      const emittedArrayValue = emittedValues.find((item) => item.name === 'tags').value;

      expect(Array.isArray(emittedArrayValue)).toBe(true);
      expect(emittedArrayValue).toEqual([{ key: 'value' }, { another: 'object' }]);
    });

    it('restores input defaults and emits empty array when all inputs are deselected', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();

      expect(wrapper.emitted('update-inputs')).toHaveLength(1);

      const updatedInput = { ...expectedInputs[0], value: 'updated-value', isSelected: true };
      findInputsTable().vm.$emit('update', updatedInput);

      expect(wrapper.emitted('update-inputs')).toHaveLength(2);

      const expectedEmittedValue = [
        { name: 'deploy_environment', value: 'updated-value' },
        { name: 'api_token', value: '' },
        { name: 'tags', value: '' },
      ];

      expect(wrapper.emitted('update-inputs')[1][0]).toEqual(expectedEmittedValue);

      findInputsSelector().vm.$emit('reset');
      await nextTick();

      expect(wrapper.emitted('update-inputs')).toHaveLength(3);
      expect(wrapper.emitted('update-inputs')[2][0]).toEqual([]);
    });
  });

  describe('input metadata update event handling', () => {
    beforeEach(async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();
    });

    it('emits total available and modified counts when receives the inputs', () => {
      expect(wrapper.emitted()['update-inputs-metadata']).toHaveLength(2);
      expect(wrapper.emitted()['update-inputs-metadata'][0][0]).toEqual({
        totalAvailable: 3,
        totalModified: 0,
      });
    });

    it('emits updated metadata values when inputs are updated', () => {
      const inputs = getTableInputs();
      const updatedInput = { ...inputs[0], savedValue: 'saved-value', value: 'new-updated-value' };
      findInputsTable().vm.$emit('update', updatedInput);

      expect(wrapper.emitted()['update-inputs-metadata']).toHaveLength(3);
      expect(wrapper.emitted()['update-inputs-metadata'][2][0]).toEqual({
        totalModified: 1,
        newlyModified: 1,
      });
    });
  });

  describe('dynamic rules', () => {
    beforeEach(async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsWithRules);
      await createComponent();
    });

    it('excludes inputs with rules from the inputs selector', () => {
      expect(findInputsSelector().props('items')).toEqual([
        { text: 'cloud_provider', value: 'cloud_provider' },
        { text: 'environment', value: 'environment' },
      ]);
    });

    it('auto-selects child when parents are selected', async () => {
      await selectInputs(['cloud_provider', 'environment']);

      const instanceType = getInputByName('instance_type');

      expect(instanceType.isSelected).toBe(true);
      expect(instanceType.options).toEqual(['t3.micro', 't3.small']);
    });

    it('maintains child selection when partial parent conditions still match a rule', async () => {
      await selectInputs(['cloud_provider', 'environment']);

      findInputsTable().vm.$emit('update', {
        name: 'cloud_provider',
        value: 'gcp',
        isSelected: true,
        hasRules: false,
      });
      await nextTick();

      expect(getInputByName('instance_type').isSelected).toBe(true);
      expect(getInputByName('instance_type').options).toEqual(['e2-small', 'e2-medium']);
      expect(getInputByName('instance_type').value).toBe('e2-small');

      await selectInputs(['cloud_provider']); // Unselecting input restores the default value

      expect(getInputByName('instance_type').isSelected).toBe(true);
      expect(getInputByName('instance_type').options).toEqual(['e2-small', 'e2-medium']);
    });

    it('updates child options and preserves value if still valid', async () => {
      await selectInputs(['cloud_provider', 'environment']);

      expect(getInputByName('instance_type').options).toEqual(['t3.micro', 't3.small']);
      expect(getInputByName('instance_type').value).toBe('t3.micro');

      findInputsTable().vm.$emit('update', {
        name: 'environment',
        value: 'prod',
        isSelected: true,
        hasRules: false,
      });
      await nextTick();

      expect(getInputByName('instance_type').options).toEqual(['m5.large', 'm5.xlarge']);
      expect(getInputByName('instance_type').value).toBe('m5.large');
    });

    it('deselects child and clears options when no rules match after parent update', async () => {
      await selectInputs(['cloud_provider', 'environment']);

      expect(getInputByName('instance_type').isSelected).toBe(true);
      expect(getInputByName('instance_type').options).toEqual(['t3.micro', 't3.small']);

      findInputsTable().vm.$emit('update', {
        name: 'environment',
        value: 'test',
        isSelected: true,
        hasRules: false,
      });
      await nextTick();

      expect(getInputByName('instance_type').isSelected).toBe(false);
      expect(getInputByName('instance_type').options).toEqual([]);
      expect(getInputByName('instance_type').value).toBe('');
    });
  });

  describe('dynamic rules with complex nested conditions', () => {
    beforeEach(async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsWithComplexRules);
      await createComponent();
    });

    it('evaluates OR conditions correctly - first branch (AND condition)', async () => {
      // Test: (aws && prod) || azure
      // This tests the first branch: aws && prod
      await selectInputs(['cloud_provider', 'environment']);

      findInputsTable().vm.$emit('update', {
        name: 'environment',
        value: 'prod',
        isSelected: true,
        hasRules: false,
      });
      await nextTick();

      expect(getInputByName('special_feature').isSelected).toBe(true);
      expect(getInputByName('special_feature').options).toEqual([
        'premium-feature',
        'enterprise-feature',
      ]);
    });

    it('evaluates OR conditions correctly - second branch (single condition)', async () => {
      // Test: (aws && prod) || azure
      // This tests the second branch: just azure
      await selectInputs(['cloud_provider', 'environment']);

      findInputsTable().vm.$emit('update', {
        name: 'cloud_provider',
        value: 'azure',
        isSelected: true,
        hasRules: false,
      });

      findInputsTable().vm.$emit('update', {
        name: 'environment',
        value: 'dev', // Explicitly set to dev to ensure it's not prod
        isSelected: true,
        hasRules: false,
      });
      await nextTick();

      expect(getInputByName('special_feature').isSelected).toBe(true);
      expect(getInputByName('special_feature').options).toEqual([
        'premium-feature',
        'enterprise-feature',
      ]);
    });

    it('does not match OR condition when neither branch is satisfied', async () => {
      // Test: (aws && prod) || azure
      // Neither condition is met: gcp && dev
      await selectInputs(['cloud_provider', 'environment']);

      findInputsTable().vm.$emit('update', {
        name: 'cloud_provider',
        value: 'gcp',
        isSelected: true,
        hasRules: false,
      });
      await nextTick();

      expect(getInputByName('special_feature').isSelected).toBe(false);
      expect(getInputByName('special_feature').options).toEqual([]);
    });
  });
});
