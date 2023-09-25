<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST, WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

export default {
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  WORKSPACE_PROJECT,
  components: {
    ConfidentialityBadge,
    HiddenBadge,
    LockedBadge,
  },
  inject: ['hidden'],
  computed: {
    ...mapGetters(['getNoteableData']),
    isLocked() {
      return this.getNoteableData.discussion_locked;
    },
    isConfidential() {
      return this.getNoteableData.confidential;
    },
  },
};
</script>

<template>
  <span class="gl-display-contents">
    <confidentiality-badge
      v-if="isConfidential"
      class="gl-align-self-center gl-mr-2"
      :issuable-type="$options.TYPE_ISSUE"
      :workspace-type="$options.WORKSPACE_PROJECT"
    />
    <locked-badge
      v-if="isLocked"
      class="gl-align-self-center gl-mr-2"
      :issuable-type="$options.TYPE_MERGE_REQUEST"
    />
    <hidden-badge
      v-if="hidden"
      class="gl-align-self-center gl-mr-2"
      :issuable-type="$options.TYPE_MERGE_REQUEST"
    />
  </span>
</template>
