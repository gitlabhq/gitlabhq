<script>
import { mapActions, mapGetters } from 'vuex';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { REVIEW_BAR_VISIBLE_CLASS_NAME } from '../constants';
import { PREVENT_LEAVING_PENDING_REVIEW } from '../i18n';
import PreviewDropdown from './preview_dropdown.vue';
import PublishButton from './publish_button.vue';
import SubmitDropdown from './submit_dropdown.vue';

function closeInterrupt(event) {
  event.preventDefault();

  // This is the correct way to write backwards-compatible beforeunload listeners
  // https://developer.chrome.com/blog/page-lifecycle-api/#the-beforeunload-event
  /* eslint-disable-next-line no-return-assign, no-param-reassign */
  return (event.returnValue = PREVENT_LEAVING_PENDING_REVIEW);
}

export default {
  components: {
    PreviewDropdown,
    PublishButton,
    SubmitDropdown,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    ...mapGetters(['isNotesFetched']),
  },
  watch: {
    isNotesFetched() {
      if (this.isNotesFetched) {
        this.expandAllDiscussions();
      }
    },
  },
  mounted() {
    document.body.classList.add(REVIEW_BAR_VISIBLE_CLASS_NAME);
    /*
     * This stuff is a lot trickier than it looks.
     *
     * Mandatory reading: https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event
     * Some notable sentences:
     *     - "[...] browsers may not display prompts created in beforeunload event handlers unless the
     *         page has been interacted with, or may even not display them at all."
     *     - "Especially on mobile, the beforeunload event is not reliably fired."
     *     - "The beforeunload event is not compatible with the back/forward cache (bfcache) [...]
     *         It is recommended that developers listen for beforeunload only in this scenario, and only
     *         when they actually have unsaved changes, so as to minimize the effect on performance."
     *
     * Please ensure that this is really not working before you modify it, because there are a LOT
     * of scenarios where browser behavior will make it _seem_ like it's not working, but it actually
     * is under the right combination of contexts.
     */
    window.addEventListener('beforeunload', closeInterrupt, { capture: true });
  },
  beforeDestroy() {
    window.removeEventListener('beforeunload', closeInterrupt, { capture: true });
    document.body.classList.remove(REVIEW_BAR_VISIBLE_CLASS_NAME);
  },
  methods: {
    ...mapActions('batchComments', ['expandAllDiscussions']),
  },
};
</script>
<template>
  <div>
    <nav class="review-bar-component" data-testid="review_bar_component">
      <div
        class="review-bar-content d-flex gl-justify-content-end"
        data-qa-selector="review_bar_content"
      >
        <preview-dropdown />
        <publish-button v-if="!glFeatures.mrReviewSubmitComment" class="gl-ml-3" show-count />
        <submit-dropdown v-else />
      </div>
    </nav>
  </div>
</template>
