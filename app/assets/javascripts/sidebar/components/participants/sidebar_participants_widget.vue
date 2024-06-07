<script>
import { __ } from '~/locale';
import { participantsQueries } from '../../queries/constants';
import SidebarParticipants from './sidebar_participants.vue';

export default {
  i18n: {
    fetchingError: __('An error occurred while fetching participants'),
  },
  components: {
    SidebarParticipants,
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
      skip() {
        return !this.iid;
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
  <sidebar-participants
    :loading="isLoading"
    :participants="participants"
    :number-of-less-participants="8"
    :lazy="false"
    class="block participants"
    @toggleSidebar="$emit('toggleSidebar')"
  />
</template>
