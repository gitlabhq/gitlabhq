<script>
import Vue from 'vue';
import { fetchPolicies } from '~/lib/graphql';
import StatusBadge from '~/issuable/components/status_badge.vue';

export const badgeState = Vue.observable({
  state: '',
  updateStatus: null,
});

export default {
  components: {
    StatusBadge,
  },
  inject: {
    query: { default: null },
    projectPath: { default: null },
    iid: { default: null },
  },
  props: {
    initialState: {
      type: String,
      required: false,
      default: null,
    },
    issuableType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    if (!this.iid) {
      return {
        state: this.initialState,
      };
    }

    if (!badgeState.state && this.initialState) {
      badgeState.state = this.initialState;
    }

    return badgeState;
  },
  created() {
    if (!badgeState.updateStatus) {
      badgeState.updateStatus = this.fetchState;
    }
  },
  beforeDestroy() {
    if (badgeState.updateStatus && this.query) {
      badgeState.updateStatus = null;
    }
  },
  methods: {
    async fetchState() {
      const { data } = await this.$apollo.query({
        query: this.query,
        variables: {
          projectPath: this.projectPath,
          iid: this.iid,
        },
        fetchPolicy: fetchPolicies.NO_CACHE,
      });

      badgeState.state = data?.workspace?.issuable?.state;
    },
  },
};
</script>

<template>
  <status-badge class="gl-align-self-center gl-mr-3" :issuable-type="issuableType" :state="state" />
</template>
