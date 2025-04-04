import Vue from 'vue';
import { GlButton } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SubmitReviewButton from '~/batch_comments/components/submit_review_button.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import DraftsCount from '~/batch_comments/components/drafts_count.vue';

Vue.use(PiniaVuePlugin);

describe('SubmitReviewButton', () => {
  let wrapper;
  let pinia;

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    wrapper = shallowMountExtended(SubmitReviewButton, {
      pinia,
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({
      plugins: [globalAccessorPlugin],
    });
    useLegacyDiffs();
    useNotes();
    useBatchComments();
    useBatchComments().isReviewer = true;
  });

  it('shows toggle button when drats are not empty', () => {
    useBatchComments().drafts = [{}];
    useBatchComments().isReviewer = false;
    createComponent();
    expect(findButton().exists()).toBe(true);
  });

  it('shows toggle button when user is a reviewer', () => {
    createComponent();
    expect(findButton().exists()).toBe(true);
  });

  it('hides toggle button when user is not a reviewer and there are no drafts', () => {
    useBatchComments().isReviewer = false;
    createComponent();
    expect(findButton().exists()).toBe(false);
  });

  it('shows drafts count', () => {
    useBatchComments().drafts = [{}];
    createComponent();
    expect(wrapper.findComponent(DraftsCount).exists()).toBe(true);
  });

  it('hides drafts count', () => {
    createComponent();
    expect(wrapper.findComponent(DraftsCount).exists()).toBe(false);
  });

  it('opens drawer', async () => {
    createComponent();
    await findButton().vm.$emit('click');
    expect(useBatchComments().setDrawerOpened).toHaveBeenCalledWith(true);
  });
});
