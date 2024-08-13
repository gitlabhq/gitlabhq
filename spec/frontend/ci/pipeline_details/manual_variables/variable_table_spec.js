import { nextTick } from 'vue';
import { GlPagination, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import VariableTable from '~/ci/pipeline_details/manual_variables/variable_table.vue';
import { generateVariablePairs } from './mock_data';

const defaultCanReadVariables = true;
const defaultManualVariablesCount = 0;

describe('ManualVariableTable', () => {
  let wrapper;

  const createComponent = (provides = {}, variables = []) => {
    wrapper = mountExtended(VariableTable, {
      provide: {
        manualVariablesCount: defaultManualVariablesCount,
        canReadVariables: defaultCanReadVariables,
        ...provides,
      },
      propsData: {
        variables,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findPaginator = () => wrapper.findComponent(GlPagination);
  const findValues = () => wrapper.findAllByTestId('manual-variable-value');

  describe('when component is created', () => {
    describe('reveal/hide button', () => {
      it('should render the button when has permissions', () => {
        createComponent();

        expect(findButton().exists()).toBe(true);
      });

      it('should not render the button when does not have permissions', () => {
        createComponent({
          canReadVariables: false,
        });

        expect(findButton().exists()).toBe(false);
      });
    });

    describe('paginator', () => {
      it('should not render paginator without any data', () => {
        createComponent();

        expect(findPaginator().exists()).toBe(false);
      });

      it('should not render paginator with data less or equal to 15', () => {
        const mockData = generateVariablePairs(15);
        createComponent(
          {
            manualVariablesCount: mockData.length,
          },
          mockData,
        );

        expect(findPaginator().exists()).toBe(false);
      });

      it('should render paginator when data is greater than 15', () => {
        const mockData = generateVariablePairs(16);

        createComponent(
          {
            manualVariablesCount: mockData.length,
          },
          mockData,
        );

        expect(findPaginator().exists()).toBe(true);
      });
    });
  });

  describe('when click on the reveal/hide button', () => {
    it('should toggle button text', async () => {
      createComponent();
      const button = findButton();

      expect(button.text()).toBe('Reveal values');
      button.vm.$emit('click');
      await nextTick();
      expect(button.text()).toBe('Hide values');
    });

    it('should reveal the values when click on the button', async () => {
      const mockData = generateVariablePairs(15);

      createComponent(
        {
          manualVariablesCount: mockData.length,
        },
        mockData,
      );

      const values = findValues();
      expect(values).toHaveLength(mockData.length);

      expect(values.wrappers.every((w) => w.text() === '****')).toBe(true);

      await findButton().trigger('click');

      expect(values.wrappers.map((w) => w.text())).toStrictEqual(mockData.map((d) => d.value));
    });
  });
});
