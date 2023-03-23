import { shallowMount } from '@vue/test-utils';
import DataframeOutput from '~/notebook/cells/output/dataframe.vue';
import JSONTable from '~/behaviors/components/json_table.vue';
import { outputWithDataframe } from '../../mock_data';

describe('~/notebook/cells/output/DataframeOutput', () => {
  let wrapper;

  function createComponent(rawCode) {
    wrapper = shallowMount(DataframeOutput, {
      propsData: {
        rawCode,
        count: 0,
        index: 0,
      },
    });
  }

  const findTable = () => wrapper.findComponent(JSONTable);

  describe('with valid dataframe', () => {
    beforeEach(() => createComponent(outputWithDataframe.data['text/html'].join('')));

    it('mounts the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('table caption is empty', () => {
      expect(findTable().props().caption).toEqual('');
    });

    it('allows filtering', () => {
      expect(findTable().props().hasFilter).toBe(true);
    });

    it('sets the correct fields', () => {
      expect(findTable().props().fields).toEqual([
        { key: 'index', label: '', sortable: true },
        { key: 'column_1', label: 'column_1', sortable: true },
        { key: 'column_2', label: 'column_2', sortable: true },
      ]);
    });

    it('sets the correct items', () => {
      expect(findTable().props().items).toEqual([
        { index: 0, column_1: 'abc de f', column_2: 'a' },
        { index: 1, column_1: 'True', column_2: '0.1' },
      ]);
    });
  });

  describe('invalid dataframe', () => {
    it('still displays the table', () => {
      createComponent('dataframe');

      expect(findTable().exists()).toBe(true);
    });
  });
});
