import { shallowMount } from '@vue/test-utils';
import { GlTableLite } from '@gitlab/ui';
import PipelineInputsTable from '~/ci/common/pipeline_inputs/pipeline_inputs_table.vue';

describe('PipelineInputsTable', () => {
  let wrapper;

  const defaultProps = {
    inputs: [
      { name: 'input1', description: '', type: '', value: 'value1' },
      { name: 'input2', description: '', type: '', value: 'value2' },
    ],
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(PipelineInputsTable, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);

  describe('on render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the table', () => {
      expect(findTable().exists()).toBe(true);
    });
  });
});
