import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import { visitUrl } from '~/lib/utils/url_utility';
import PreviewDropdown from '~/batch_comments/components/preview_dropdown.vue';
import PreviewItem from '~/batch_comments/components/preview_item.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.requireActual('~/lib/utils/url_utility').setUrlParams,
}));

Vue.use(Vuex);

let wrapper;

const setCurrentFileHash = jest.fn();
const scrollToDraft = jest.fn();

const findPreviewItem = () => wrapper.findComponent(PreviewItem);

function factory({ viewDiffsFileByFile = false, draftsCount = 1, sortedDrafts = [] } = {}) {
  const store = new Vuex.Store({
    modules: {
      diffs: {
        namespaced: true,
        actions: {
          setCurrentFileHash,
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
      notes: {
        getters: {
          getNoteableData: () => ({ diff_head_sha: '123' }),
        },
      },
    },
  });

  wrapper = mount(PreviewDropdown, {
    store,
    stubs: {
      PreviewItem: true,
    },
  });
}

describe('Batch comments preview dropdown', () => {
  describe('clicking draft', () => {
    it('toggles active file when viewDiffsFileByFile is true', async () => {
      factory({
        viewDiffsFileByFile: true,
        sortedDrafts: [{ id: 1, file_hash: 'hash' }],
      });
      findPreviewItem().trigger('click');
      await nextTick();

      expect(setCurrentFileHash).toHaveBeenCalledWith(expect.anything(), 'hash');

      await nextTick();
      expect(scrollToDraft).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ id: 1, file_hash: 'hash' }),
      );
    });

    it('calls scrollToDraft', async () => {
      factory({
        viewDiffsFileByFile: false,
        sortedDrafts: [{ id: 1 }],
      });

      findPreviewItem().trigger('click');

      await nextTick();

      expect(scrollToDraft).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ id: 1 }),
      );
    });

    it('changes window location to navigate to commit', async () => {
      factory({
        viewDiffsFileByFile: false,
        sortedDrafts: [{ id: 1, position: { head_sha: '1234' } }],
      });

      findPreviewItem().trigger('click');

      await nextTick();

      expect(scrollToDraft).not.toHaveBeenCalled();
      expect(visitUrl).toHaveBeenCalledWith(`${TEST_HOST}/?commit_id=1234#note_1`);
    });
  });
});
