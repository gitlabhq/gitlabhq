<script>
import { __ } from '~/locale';
import { participantsQueries } from '~/sidebar/constants';
import Participants from './participants.vue';

export default {
  i18n: {
    fetchingError: __('An error occurred while fetching participants'),
  },
  components: {
    Participants,
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      participants: [],
    };
  },
  apollo: {
    participants: {
      query() {
        return participantsQueries[this.issuableType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update(data) {
        return data.workspace?.issuable?.participants.nodes || [];
      },
      error(error) {
        this.$emit('fetch-error', {
          message: this.$options.i18n.fetchingError,
          error,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.participants.loading;
    },
  },
};
</script>

<template>
  <participants
    :loading="isLoading"
    :participants="participants"
    :number-of-less-participants="7"
    class="block participants"
  />
</template>
