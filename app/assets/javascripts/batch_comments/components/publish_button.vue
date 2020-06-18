<script>
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import DraftsCount from './drafts_count.vue';

export default {
  components: {
    LoadingButton,
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
  <loading-button
    :loading="isPublishing"
    container-class="btn btn-success js-publish-draft-button qa-submit-review"
    @click="onClick"
  >
    <span>
      {{ label }}
      <drafts-count v-if="showCount" />
    </span>
  </loading-button>
</template>
