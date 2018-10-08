<script>
import { mapActions, mapState } from 'vuex';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import DraftsCount from './drafts_count.vue';

export default {
  components: {
    LoadingButton,
    DraftsCount,
  },
  computed: {
    ...mapState('batchComments', ['isPublishing']),
  },
  methods: {
    ...mapActions('batchComments', ['publishReview']),
  },
};
</script>

<template>
  <loading-button
    :loading="isPublishing"
    container-class="btn btn-success"
    @click="publishReview"
  >
    <span>
      {{ __('Submit review') }}
      <drafts-count />
    </span>
  </loading-button>
</template>
