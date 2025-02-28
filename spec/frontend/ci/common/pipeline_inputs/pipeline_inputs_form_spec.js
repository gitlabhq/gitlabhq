import { shallowMount } from '@vue/test-utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import PipelineInputsTable from '~/ci/common/pipeline_inputs/pipeline_inputs_table.vue';

describe('PipelineInputsForm', () => {
  let wrapper;

  const mockInputs = [
    { name: 'input1', value: 'value1' },
    { name: 'input2', value: 'value2' },
  ];

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(PipelineInputsForm, {
      propsData: {
        inputs: mockInputs,
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
          count: mockInputs.length,
        });
      });
    });

    it('renders a table', () => {
      expect(findInputsTable().exists()).toBe(true);
    });
  });
});
