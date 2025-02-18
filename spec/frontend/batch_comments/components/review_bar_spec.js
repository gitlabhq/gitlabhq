import { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ReviewBar from '~/batch_comments/components/review_bar.vue';
import { REVIEW_BAR_VISIBLE_CLASS_NAME } from '~/batch_comments/constants';
import toast from '~/vue_shared/plugins/global_toast';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import createStore from '../create_batch_comments_store';

jest.mock('~/vue_shared/plugins/global_toast');

describe('Batch comments review bar component', () => {
  let store;
  let wrapper;

  const findDiscardReviewButton = () => wrapper.findByTestId('discard-review-btn');
  const findDiscardReviewModal = () => wrapper.findByTestId('discard-review-modal');

  const createComponent = (propsData = {}) => {
    store = createStore();

    wrapper = shallowMountExtended(ReviewBar, {
      store,
      propsData,
    });
  };

  beforeEach(() => {
    createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    document.body.className = '';
  });

  it('adds review-bar-visible class to body when review bar is mounted', () => {
    expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(false);

    createComponent();

    expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(true);
  });

  it('removes review-bar-visible class to body when review bar is destroyed', () => {
    createComponent();

    wrapper.destroy();

    expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(false);
  });

  describe('when discarding a review', () => {
    it('shows modal when clicking discard button', async () => {
      createComponent();

      expect(findDiscardReviewModal().props('visible')).toBe(false);

      findDiscardReviewButton().vm.$emit('click');

      await nextTick();

      expect(findDiscardReviewModal().props('visible')).toBe(true);
    });

    it('calls discardReviews when primary action on modal is triggered', () => {
      createComponent();

      findDiscardReviewModal().vm.$emit('primary');

      expect(useBatchComments().discardDrafts).toHaveBeenCalled();
    });

    it('creates a toast message when finished', async () => {
      createComponent();

      jest.spyOn(store, 'dispatch').mockImplementation();

      findDiscardReviewModal().vm.$emit('primary');

      await nextTick();

      expect(toast).toHaveBeenCalledWith('Review discarded');
    });
  });
});
