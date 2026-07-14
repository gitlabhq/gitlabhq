<script>
import { GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { createAlert } from '~/alert';
import { __, n__ } from '~/locale';
import { useBatchComments } from '~/batch_comments/store';
import { useNotes } from '~/notes/store/legacy_notes';

export default {
  name: 'SubmitReviewButton',
  components: {
    GlButton,
  },
  computed: {
    ...mapState(useNotes, ['isNotesFetched']),
    ...mapState(useBatchComments, [
      'draftsCount',
      'isDraftsFetched',
      'isReviewer',
      'shouldAnimateReviewButton',
    ]),
    isLoading() {
      return !this.isNotesFetched || !this.isDraftsFetched;
    },
    draftsCountSrText() {
      return n__('draft', 'drafts', this.draftsCount);
    },
  },
  mounted() {
    this.fetchDrafts().catch((error) => {
      createAlert({
        message: __('An error occurred while fetching pending comments'),
        captureError: true,
        error,
      });
    });
  },
  methods: {
    ...mapActions(useBatchComments, ['fetchDrafts', 'setDrawerOpened']),
  },
};
</script>

<template>
  <div v-if="draftsCount > 0 || isReviewer" data-testid="review-drawer-toggle">
    <gl-button
      variant="confirm"
      data-testid="review-drawer-toggle"
      :disabled="isLoading"
      :loading="isLoading"
      :count="draftsCount > 0 ? draftsCount : null"
      :count-sr-text="draftsCountSrText"
      :class="{
        'motion-safe:gl-animate-[review-btn-animate_300ms_ease-in]': shouldAnimateReviewButton,
      }"
      @click="setDrawerOpened(true)"
    >
      {{ __('Your review') }}
    </gl-button>
  </div>
</template>
