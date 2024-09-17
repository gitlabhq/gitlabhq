<script>
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import StatusBadge from '~/issuable/components/status_badge.vue';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST, WORKSPACE_PROJECT } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';

export const badgeState = Vue.observable({
  state: '',
  updateStatus: null,
});

export default {
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  WORKSPACE_PROJECT,
  components: {
    ConfidentialityBadge,
    LockedBadge,
    HiddenBadge,
    ImportedBadge,
    StatusBadge,
  },
  inject: {
    query: { default: null },
    projectPath: { default: null },
    hidden: { default: false },
    iid: { default: null },
  },
  props: {
    initialState: {
      type: String,
      required: false,
      default: null,
    },
    isImported: {
      type: Boolean,
      required: false,
      default: false,
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
  computed: {
    ...mapGetters(['getNoteableData']),
    isLocked() {
      return this.getNoteableData.discussion_locked;
    },
    isConfidential() {
      return this.getNoteableData.confidential;
    },
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
  <span class="gl-contents">
    <status-badge
      class="gl-mr-2 gl-self-center"
      :issuable-type="$options.TYPE_MERGE_REQUEST"
      :state="state"
    />
    <confidentiality-badge
      v-if="isConfidential"
      class="gl-mr-2 gl-self-center"
      :issuable-type="$options.TYPE_ISSUE"
      :workspace-type="$options.WORKSPACE_PROJECT"
    />
    <locked-badge
      v-if="isLocked"
      class="gl-mr-2 gl-self-center"
      :issuable-type="$options.TYPE_MERGE_REQUEST"
    />
    <hidden-badge
      v-if="hidden"
      class="gl-mr-2 gl-self-center"
      :issuable-type="$options.TYPE_MERGE_REQUEST"
    />
    <imported-badge
      v-if="isImported"
      class="gl-mr-2 gl-self-center"
      :importable-type="$options.TYPE_MERGE_REQUEST"
    />
  </span>
</template>
