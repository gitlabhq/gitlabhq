<script>
import { GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
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
    category: {
      type: String,
      required: false,
      default: 'primary',
    },
    variant: {
      type: String,
      required: false,
      default: 'confirm',
    },
  },
  computed: {
    ...mapState('batchComments', ['isPublishing']),
  },
  methods: {
    ...mapActions('batchComments', ['publishReview']),
    onClick() {
      this.publishReview();
    },
  },
};
</script>

<template>
  <gl-button
    :loading="isPublishing"
    class="js-publish-draft-button"
    data-qa-selector="submit_review_button"
    :category="category"
    :variant="variant"
    @click="onClick"
  >
    {{ __('Submit review') }}
    <drafts-count v-if="showCount" />
  </gl-button>
</template>
