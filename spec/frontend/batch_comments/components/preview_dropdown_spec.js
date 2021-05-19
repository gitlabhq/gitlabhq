import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PreviewDropdown from '~/batch_comments/components/preview_dropdown.vue';

Vue.use(Vuex);

let wrapper;

const toggleActiveFileByHash = jest.fn();
const scrollToDraft = jest.fn();

function factory({ viewDiffsFileByFile = false, draftsCount = 1, sortedDrafts = [] } = {}) {
  const store = new Vuex.Store({
    modules: {
      diffs: {
        namespaced: true,
        actions: {
          toggleActiveFileByHash,
        },
        state: {
          viewDiffsFileByFile,
        },
      },
      batchComments: {
        namespaced: true,
        actions: { scrollToDraft },
        getters: { draftsCount: () => draftsCount, sortedDrafts: () => sortedDrafts },
      },
    },
  });

  wrapper = shallowMountExtended(PreviewDropdown, {
    store,
  });
}

describe('Batch comments preview dropdown', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  describe('clicking draft', () => {
    it('it toggles active file when viewDiffsFileByFile is true', async () => {
      factory({
        viewDiffsFileByFile: true,
        sortedDrafts: [{ id: 1, file_hash: 'hash' }],
      });

      wrapper.findByTestId('preview-item').vm.$emit('click');

      await Vue.nextTick();

      expect(toggleActiveFileByHash).toHaveBeenCalledWith(expect.anything(), 'hash');
      expect(scrollToDraft).toHaveBeenCalledWith(expect.anything(), { id: 1, file_hash: 'hash' });
    });

    it('calls scrollToDraft', async () => {
      factory({
        viewDiffsFileByFile: false,
        sortedDrafts: [{ id: 1 }],
      });

      wrapper.findByTestId('preview-item').vm.$emit('click');

      await Vue.nextTick();

      expect(scrollToDraft).toHaveBeenCalledWith(expect.anything(), { id: 1 });
    });
  });
});
