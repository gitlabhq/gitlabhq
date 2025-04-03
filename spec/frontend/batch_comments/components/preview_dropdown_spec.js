import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { TEST_HOST } from 'helpers/test_constants';
import { visitUrl } from '~/lib/utils/url_utility';
import PreviewDropdown from '~/batch_comments/components/preview_dropdown.vue';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { createCustomGetters } from 'helpers/pinia_helpers';
import { useBatchComments } from '~/batch_comments/store';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.requireActual('~/lib/utils/url_utility').setUrlParams,
  getParameterValues: jest.requireActual('~/lib/utils/url_utility').getParameterValues,
  joinPaths: jest.fn(),
  doesHashExistInUrl: jest.fn(),
}));

Vue.use(Vuex);
Vue.use(PiniaVuePlugin);

describe('Batch comments preview dropdown', () => {
  let wrapper;
  let pinia;
  let batchCommentsGetters;

  const findPreviewItem = () => wrapper.findComponent(PreviewItem);

  function factory({ draftsCount = 1, sortedDrafts = [] } = {}) {
    batchCommentsGetters = {
      draftsCount,
      sortedDrafts,
    };
    const store = new Vuex.Store({
      modules: {
        notes: {
          getters: {
            getNoteableData: () => ({ diff_head_sha: '123' }),
          },
        },
      },
    });

    wrapper = mount(PreviewDropdown, {
      store,
      pinia,
      stubs: {
        PreviewItem: true,
      },
    });
  }

  beforeEach(() => {
    batchCommentsGetters = {};
    pinia = createTestingPinia({
      plugins: [
        globalAccessorPlugin,
        createCustomGetters(() => ({
          batchComments: batchCommentsGetters,
          legacyNotes: {},
          legacyDiffs: {},
        })),
      ],
    });
    useLegacyDiffs();
    useNotes();
  });

  describe('clicking draft', () => {
    it('toggles active file when viewDiffsFileByFile is true', async () => {
      useLegacyDiffs().viewDiffsFileByFile = true;
      factory({
        sortedDrafts: [{ id: 1, file_hash: 'hash', file_path: 'foo' }],
      });
      findPreviewItem().trigger('click');
      await nextTick();

      expect(useLegacyDiffs().goToFile).toHaveBeenCalledWith({ path: 'foo' });

      await nextTick();
      expect(useBatchComments().scrollToDraft).toHaveBeenCalledWith(
        expect.objectContaining({ id: 1, file_hash: 'hash' }),
      );
    });

    it('calls scrollToDraft', async () => {
      useLegacyDiffs().viewDiffsFileByFile = false;
      factory({
        sortedDrafts: [{ id: 1 }],
      });

      findPreviewItem().trigger('click');

      await nextTick();

      expect(useBatchComments().scrollToDraft).toHaveBeenCalledWith(
        expect.objectContaining({ id: 1 }),
      );
    });

    it('changes window location to navigate to commit', async () => {
      useLegacyDiffs().viewDiffsFileByFile = false;
      factory({
        sortedDrafts: [{ id: 1, position: { head_sha: '1234' } }],
      });

      findPreviewItem().trigger('click');

      await nextTick();

      expect(useBatchComments().scrollToDraft).not.toHaveBeenCalled();
      expect(visitUrl).toHaveBeenCalledWith(`${TEST_HOST}/?commit_id=1234#note_1`);
    });
  });
});
