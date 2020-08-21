import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { createStore } from '~/mr_notes/stores';
import ParallelDiffView from '~/diffs/components/parallel_diff_view.vue';
import parallelDiffTableRow from '~/diffs/components/parallel_diff_table_row.vue';
import diffFileMockData from '../mock_data/diff_file';

let wrapper;
const localVue = createLocalVue();

localVue.use(Vuex);

function factory() {
  const diffFile = { ...diffFileMockData };
  const store = createStore();

  wrapper = shallowMount(ParallelDiffView, {
    localVue,
    store,
    propsData: {
      diffFile,
      diffLines: diffFile.parallel_diff_lines,
    },
  });
}

describe('ParallelDiffView', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders diff lines', () => {
    factory();

    expect(wrapper.findAll(parallelDiffTableRow).length).toBe(8);
  });
});
