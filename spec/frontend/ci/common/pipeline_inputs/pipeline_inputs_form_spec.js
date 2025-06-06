import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import CrudComponent from '~/vue_shared/components/crud_component.vue';
import InputsTableSkeletonLoader from '~/ci/common/pipeline_inputs/pipeline_inputs_table/inputs_table_skeleton_loader.vue';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import PipelineInputsTable from '~/ci/common/pipeline_inputs/pipeline_inputs_table/pipeline_inputs_table.vue';
import getPipelineInputsQuery from '~/ci/common/pipeline_inputs/graphql/queries/pipeline_creation_inputs.query.graphql';
/** mock data to be replaced with fixtures - https://gitlab.com/gitlab-org/gitlab/-/issues/525243 */
import {
  mockPipelineInputsResponse,
  mockEmptyInputsResponse,
  mockPipelineInputsErrorResponse,
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
    isSelected: false,
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
    isSelected: false,
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
    isSelected: false,
  },
];

describe('PipelineInputsForm', () => {
  let wrapper;
  let pipelineInputsHandler;

  const createComponent = async ({ props = {}, provide = {} } = {}) => {
    const handlers = [[getPipelineInputsQuery, pipelineInputsHandler]];
    const mockApollo = createMockApollo(handlers);
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
  const findEmptyState = () => wrapper.findByText('There are no inputs for this configuration.');
  const findEmptySelectionState = () => wrapper.findByTestId('empty-selection-state');
  const findInputsSelector = () => wrapper.findComponent(GlCollapsibleListbox);

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
          disabled: false,
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
          expect(findInputsTable().props('inputs')).toEqual(updatedSelection);
        });

        it('removes isSelected property when deselected', async () => {
          await selectInputs(['api_token', 'tags']);
          const updatedSelection = [
            { ...expectedInputs[0], isSelected: false },
            { ...expectedInputs[1], isSelected: true },
            { ...expectedInputs[2], isSelected: true },
          ];
          expect(findInputsTable().props('inputs')).toEqual(updatedSelection);
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
      });
    });

    describe('with no inputs', () => {
      beforeEach(async () => {
        pipelineInputsHandler = jest.fn().mockResolvedValue(mockEmptyInputsResponse);
        await createComponent();
      });

      it('renders input selector listbox as disabled', () => {
        expect(findInputsSelector().props('disabled')).toBe(true);
      });

      it('does not render a table', () => {
        expect(findInputsTable().exists()).toBe(false);
      });

      it('displays the empty state message', () => {
        expect(findEmptyState().exists()).toBe(true);
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
      expect(findInputsTable().props('inputs')).toEqual(updatedSelection);
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
      expect(findInputsTable().props('inputs')).toEqual(updatedSelection);
    });
  });

  describe('input update event handling', () => {
    it('processes and emits update events from the table component', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();

      const updatedInput = { ...expectedInputs[0], value: 'updated-value' };
      findInputsTable().vm.$emit('update', updatedInput);

      expect(wrapper.emitted()['update-inputs']).toHaveLength(1);

      const expectedEmittedValue = [
        { name: 'deploy_environment', value: 'updated-value' },
        { name: 'api_token', value: '' },
        { name: 'tags', value: '' },
      ];

      expect(wrapper.emitted()['update-inputs'][0][0]).toEqual(expectedEmittedValue);
    });

    it('only emits modified inputs when emitModifiedOnly is true', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent({ props: { emitModifiedOnly: true } });
      await selectInputs();

      const inputs = findInputsTable().props('inputs');
      const totalInputsCount = inputs.length;
      const inputToModify = { ...inputs[0], value: 'modified-value' };

      findInputsTable().vm.$emit('update', inputToModify);

      const emittedNameValuePairs = wrapper.emitted()['update-inputs'][0][0];

      expect(emittedNameValuePairs).toHaveLength(1);
      expect(emittedNameValuePairs.length).toBeLessThan(totalInputsCount);
    });

    it('converts string values to arrays for ARRAY type inputs', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();

      // Get the array input from the current inputs prop of the table
      const inputs = findInputsTable().props('inputs');
      const arrayInput = inputs.find((input) => input.type === 'ARRAY');

      const updatedInput = {
        ...arrayInput,
        value: '[1,2,3]',
      };

      findInputsTable().vm.$emit('update', updatedInput);

      // Check that the emitted value contains the converted array
      const emittedValues = wrapper.emitted()['update-inputs'][0][0];
      const emittedArrayValue = emittedValues.find((item) => item.name === 'tags').value;

      expect(Array.isArray(emittedArrayValue)).toBe(true);
      expect(emittedArrayValue).toEqual([1, 2, 3]);
    });

    it('converts complex object arrays correctly', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();

      const inputs = findInputsTable().props('inputs');
      const arrayInput = inputs.find((input) => input.type === 'ARRAY');

      const updatedInput = {
        ...arrayInput,
        value: '[{"key": "value"}, {"another": "object"}]',
      };

      findInputsTable().vm.$emit('update', updatedInput);

      const emittedValues = wrapper.emitted()['update-inputs'][0][0];
      const emittedArrayValue = emittedValues.find((item) => item.name === 'tags').value;

      expect(Array.isArray(emittedArrayValue)).toBe(true);
      expect(emittedArrayValue).toEqual([{ key: 'value' }, { another: 'object' }]);
    });

    it('restores default values when inputs are deselected', async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();

      const updatedInput = { ...expectedInputs[0], value: 'updated-value' };
      findInputsTable().vm.$emit('update', updatedInput);

      expect(wrapper.emitted()['update-inputs']).toHaveLength(1);

      const expectedEmittedValue = [
        { name: 'deploy_environment', value: 'updated-value' },
        { name: 'api_token', value: '' },
        { name: 'tags', value: '' },
      ];

      expect(wrapper.emitted()['update-inputs'][0][0]).toEqual(expectedEmittedValue);

      findInputsSelector().vm.$emit('reset');
      await nextTick();

      // Note: 'staging' is a default value
      const newExpectedEmittedValue = [
        { name: 'deploy_environment', value: 'staging' },
        { name: 'api_token', value: '' },
        { name: 'tags', value: '' },
      ];
      expect(wrapper.emitted()['update-inputs']).toHaveLength(2);
      expect(wrapper.emitted()['update-inputs'][1][0]).toEqual(newExpectedEmittedValue);
    });
  });

  describe('input metadata update event handling', () => {
    beforeEach(async () => {
      pipelineInputsHandler = jest.fn().mockResolvedValue(mockPipelineInputsResponse);
      await createComponent();
      await selectInputs();
    });

    it('emits total available and modified counts when receives the inputs', () => {
      expect(wrapper.emitted()['update-inputs-metadata']).toHaveLength(1);
      expect(wrapper.emitted()['update-inputs-metadata'][0][0]).toEqual({
        totalAvailable: 3,
        totalModified: 0,
      });
    });

    it('emits updated metadata values when inputs are updated', () => {
      const inputs = findInputsTable().props('inputs');
      const updatedInput = { ...inputs[0], savedValue: 'saved-value', value: 'new-updated-value' };
      findInputsTable().vm.$emit('update', updatedInput);

      expect(wrapper.emitted()['update-inputs-metadata']).toHaveLength(2);
      expect(wrapper.emitted()['update-inputs-metadata'][1][0]).toEqual({
        totalModified: 1,
        newlyModified: 1,
      });
    });
  });
});
