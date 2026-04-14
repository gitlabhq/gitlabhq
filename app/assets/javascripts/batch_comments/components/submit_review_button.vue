<script>
import { GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { useBatchComments } from '~/batch_comments/store';
import { useNotes } from '~/notes/store/legacy_notes';
import DraftsCount from './drafts_count.vue';

export default {
  name: 'SubmitReviewButton',
  components: {
    GlButton,
    DraftsCount,
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
      :class="{
        'motion-safe:gl-animate-[review-btn-animate_300ms_ease-in]': shouldAnimateReviewButton,
      }"
      @click="setDrawerOpened(true)"
    >
      {{ __('Your review') }}
      <drafts-count
        v-if="draftsCount > 0"
        variant="info"
        data-testid="reviewer-drawer-drafts-count-badge"
      />
    </gl-button>
  </div>
</template>
