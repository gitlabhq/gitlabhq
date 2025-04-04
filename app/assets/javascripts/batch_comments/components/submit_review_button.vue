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
    ...mapState(useBatchComments, ['draftsCount', 'draftsCount', 'isReviewer']),
  },
  methods: {
    ...mapActions(useBatchComments, ['setDrawerOpened']),
  },
};
</script>

<template>
  <div v-if="draftsCount > 0 || isReviewer">
    <gl-button variant="confirm" data-testid="review-drawer-toggle" @click="setDrawerOpened(true)">
      {{ __('Your review') }}
      <drafts-count
        v-if="draftsCount > 0"
        variant="info"
        data-testid="reviewer-drawer-drafts-count-badge"
      />
    </gl-button>
  </div>
</template>
