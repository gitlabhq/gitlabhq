import Vue from 'vue';
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

Vue.use(PiniaVuePlugin);

describe('Merge requests sticky header component', () => {
  let wrapper;
  let pinia;

  const createComponent = ({ provide = {}, props = {} } = {}) => {
    wrapper = shallowMountExtended(StickyHeader, {
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
    useNotes().doneFetchingBatchDiscussions = true;
    useNotes().noteableData.id = 1;
    useNotes().noteableData.source_branch = 'source-branch';
    useNotes().noteableData.target_branch = 'main';
    useMrNotes().activeTab = 'overview';
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

      expect(findImportedBadge().exists()).toBe(true);
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
      createComponent();

      expect(wrapper.findComponent(SubmitReviewButton).exists()).toBe(true);
    });
  });
});
