import { createLocalVue, mount } from '@vue/test-utils';
import { GlTable, GlLoadingIcon } from '@gitlab/ui';
import Clusters from '~/clusters_list/components/clusters.vue';
import Vuex from 'vuex';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Clusters', () => {
  let wrapper;

  const findTable = () => wrapper.find(GlTable);
  const findLoader = () => wrapper.find(GlLoadingIcon);

  const mountComponent = _state => {
    const state = { clusters: [], endpoint: 'some/endpoint', ..._state };
    const store = new Vuex.Store({
      state,
    });

    wrapper = mount(Clusters, { localVue, store });
  };

  beforeEach(() => {
    mountComponent({ loading: false });
  });

  describe('clusters table', () => {
    it('displays a loader instead of the table while loading', () => {
      mountComponent({ loading: true });
      expect(findLoader().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });

    it('displays a table component', () => {
      expect(findTable().exists()).toBe(true);
      expect(findTable().exists()).toBe(true);
    });

    it('renders the correct table headers', () => {
      const tableHeaders = wrapper.vm.$options.fields;
      const headers = findTable().findAll('th');

      expect(headers.length).toBe(tableHeaders.length);

      tableHeaders.forEach((headerText, i) =>
        expect(headers.at(i).text()).toEqual(headerText.label),
      );
    });

    it('should stack on smaller devices', () => {
      expect(findTable().classes()).toContain('b-table-stacked-md');
    });
  });
});
