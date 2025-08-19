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
      participants: {},
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
        const issuableData = data.workspace?.issuable;
        return issuableData?.participants || {};
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
    participantNodes() {
      return this.participants.nodes || [];
    },
    participantCount() {
      return this.participants.count || 0;
    },
  },
};
</script>

<template>
  <sidebar-participants
    :loading="isLoading"
    :participants="participantNodes"
    :number-of-less-participants="8"
    :participant-count="participantCount"
    :lazy="false"
    class="block participants"
    @toggleSidebar="$emit('toggleSidebar')"
  />
</template>
