import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import PipelineInputsTable from '~/ci/common/pipeline_inputs/pipeline_inputs_table.vue';

describe('PipelineInputsForm', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(PipelineInputsForm, {
      propsData: {
        ...props,
      },
    });
  };

  const findInputsTable = () => wrapper.findComponent(PipelineInputsTable);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);

  describe('on render', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('crud component', () => {
      it('renders the component', () => {
        expect(findCrudComponent().exists()).toBe(true);
      });

      it('sets the correct props', () => {
        expect(findCrudComponent().props()).toMatchObject({
          title: 'Inputs',
          icon: 'code',
          description: 'Specify the input values to use in this pipeline.',
          // This will be changed to use inputs from the query data
          count: wrapper.vm.inputs.length,
        });
      });
    });

    describe('table', () => {
      it('renders a table', () => {
        expect(findInputsTable().exists()).toBe(true);
      });

      it('sends the correct props to the table', () => {
        // This will be changed to use inputs from the query data
        const { inputs } = wrapper.vm;
        expect(findInputsTable().props()).toMatchObject({ inputs });
      });
    });

    describe('event handling', () => {
      it('processes and emits update events from the table component', async () => {
        const updatedInput = { ...wrapper.vm.inputs[0], value: 'updated-value' };
        findInputsTable().vm.$emit('update', updatedInput);
        await nextTick();

        expect(wrapper.vm.inputs.find((input) => input.name === updatedInput.name).value).toBe(
          'updated-value',
        );
        expect(wrapper.emitted()['update-inputs']).toHaveLength(1);

        const expectedEmittedValue = wrapper.vm.inputs.map((input) => ({
          name: input.name,
          value: input.default,
        }));
        expect(wrapper.emitted()['update-inputs'][0][0]).toEqual(expectedEmittedValue);
      });
    });
  });
});
