<script>
import { GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { useBatchComments } from '~/batch_comments/store';
import DraftsCount from './drafts_count.vue';

export default {
  name: 'SubmitReviewButton',
  components: {
    GlButton,
    DraftsCount,
  },
  computed: {
    ...mapState(useBatchComments, ['draftsCount', 'isReviewer', 'shouldAnimateReviewButton']),
  },
  methods: {
    ...mapActions(useBatchComments, ['setDrawerOpened']),
  },
};
</script>

<template>
  <div v-if="draftsCount > 0 || isReviewer" data-testid="review-drawer-toggle">
    <gl-button
      variant="confirm"
      data-testid="review-drawer-toggle"
      :class="{ 'submit-review-dropdown-animated': shouldAnimateReviewButton }"
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
