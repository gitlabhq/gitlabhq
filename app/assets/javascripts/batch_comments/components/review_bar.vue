<script>
import { mapActions } from 'pinia';
// eslint-disable-next-line no-restricted-imports
import { mapGetters as mapVuexGetters } from 'vuex';
import { GlButton, GlTooltipDirective as GlTooltip, GlModal } from '@gitlab/ui';
import { __ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { SET_REVIEW_BAR_RENDERED } from '~/batch_comments/stores/modules/batch_comments/mutation_types';
import { useBatchComments } from '~/batch_comments/store';
import { REVIEW_BAR_VISIBLE_CLASS_NAME } from '../constants';
import PreviewDropdown from './preview_dropdown.vue';
import SubmitDropdown from './submit_dropdown.vue';

export default {
  components: {
    GlModal,
    GlButton,
    PreviewDropdown,
    SubmitDropdown,
  },
  directives: {
    GlTooltip,
  },
  data() {
    return {
      discarding: false,
      showDiscardModal: false,
    };
  },
  computed: {
    ...mapVuexGetters(['isNotesFetched']),
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
    useBatchComments()[SET_REVIEW_BAR_RENDERED]();
  },
  beforeDestroy() {
    document.body.classList.remove(REVIEW_BAR_VISIBLE_CLASS_NAME);
  },
  methods: {
    ...mapActions(useBatchComments, ['expandAllDiscussions', 'discardDrafts']),
    async discardReviews() {
      this.discarding = true;

      try {
        await this.discardDrafts();

        toast(__('Review discarded'));
      } finally {
        this.discarding = false;
      }
    },
  },
  modal: {
    cancelAction: { text: __('Keep review') },
    primaryAction: { text: __('Discard review'), attributes: { variant: 'danger' } },
  },
};
</script>
<template>
  <nav class="review-bar-component js-review-bar" data-testid="review_bar_component">
    <div class="review-bar-content gl-flex gl-justify-end" data-testid="review-bar-content">
      <gl-button
        v-gl-tooltip
        icon="remove"
        variant="danger"
        category="tertiary"
        class="gl-mr-3"
        :title="__('Discard review')"
        :aria-label="__('Discard review')"
        :loading="discarding"
        data-testid="discard-review-btn"
        @click="showDiscardModal = true"
      />
      <preview-dropdown />
      <submit-dropdown />
    </div>
    <gl-modal
      v-model="showDiscardModal"
      modal-id="discard-review-modal"
      :title="__('Discard pending review?')"
      :action-primary="$options.modal.primaryAction"
      :action-cancel="$options.modal.cancelAction"
      data-testid="discard-review-modal"
      @primary="discardReviews"
    >
      {{
        __(
          'Are you sure you want to discard your pending review comments? This action cannot be undone.',
        )
      }}
    </gl-modal>
  </nav>
</template>
