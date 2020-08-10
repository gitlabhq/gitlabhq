<script>
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import { GlButton } from '@gitlab/ui';
import DraftsCount from './drafts_count.vue';

export default {
  components: {
    GlButton,
    DraftsCount,
  },
  props: {
    showCount: {
      type: Boolean,
      required: false,
      default: false,
    },
    label: {
      type: String,
      required: false,
      default: __('Finish review'),
    },
    category: {
      type: String,
      required: false,
      default: 'primary',
    },
    variant: {
      type: String,
      required: false,
      default: 'success',
    },
    shouldPublish: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState('batchComments', ['isPublishing']),
  },
  methods: {
    ...mapActions('batchComments', ['publishReview', 'toggleReviewDropdown']),
    onClick() {
      if (this.shouldPublish) {
        this.publishReview();
      } else {
        this.toggleReviewDropdown();
      }
    },
  },
};
</script>

<template>
  <gl-button
    :loading="isPublishing"
    class="js-publish-draft-button qa-submit-review"
    :category="category"
    :variant="variant"
    @click="onClick"
  >
    {{ label }}
    <drafts-count v-if="showCount" />
  </gl-button>
</template>
