import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlSprintf } from '@gitlab/ui';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StickyHeader from '~/merge_requests/components/sticky_header.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import SubmitReviewButton from '~/batch_comments/components/submit_review_button.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';

Vue.use(Vuex);
Vue.use(PiniaVuePlugin);

describe('Merge requests sticky header component', () => {
  let wrapper;
  let pinia;

  const createComponent = ({ provide = {}, props = {} } = {}) => {
    const store = new Vuex.Store({
      state: {
        page: { activeTab: 'overview' },
        notes: { notes: { doneFetchingBatchDiscussions: true } },
      },
      getters: {
        getNoteableData: () => ({
          id: 1,
          source_branch: 'source-branch',
          target_branch: 'main',
        }),
        discussionTabCounter: () => 1,
      },
    });

    wrapper = shallowMountExtended(StickyHeader, {
      store,
      pinia,
      provide,
      propsData: {
        tabs: [],
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    useMrNotes();
  });

  describe('forked project', () => {
    it('renders source branch with source project path', () => {
      createComponent({
        provide: {
          projectPath: 'gitlab-org/gitlab',
          sourceProjectPath: 'root/gitlab',
        },
      });

      expect(wrapper.findByTestId('source-branch').text()).toBe('root/gitlab:source-branch');
    });
  });

  describe('imported badge', () => {
    it('renders when merge request is imported', () => {
      createComponent({
        props: { isImported: true },
      });

      expect(findImportedBadge().props('importableType')).toBe('merge_request');
    });

    it('does not render when merge request is not imported', () => {
      createComponent({
        props: { isImported: false },
      });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });

  describe('submit review', () => {
    it('renders submit review button', () => {
      createComponent({
        provide: { glFeatures: { improvedReviewExperience: true } },
      });

      expect(wrapper.findComponent(SubmitReviewButton).exists()).toBe(true);
    });
  });
});
