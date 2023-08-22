<script>
import { GlBadge, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';
import {
  STATUS_CLOSED,
  STATUS_OPEN,
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  TYPE_EPIC,
} from '~/issues/constants';

export const badgeState = Vue.observable({
  state: '',
  updateStatus: null,
});

const ICONS = {
  [TYPE_EPIC]: {
    opened: 'epic',
    closed: 'epic-closed',
  },
  [TYPE_ISSUE]: {
    opened: 'issues',
    locked: 'issues',
    closed: 'issue-closed',
  },
  [TYPE_MERGE_REQUEST]: {
    opened: 'merge-request-open',
    locked: 'merge-request-open',
    closed: 'merge-request-close',
    merged: 'merge',
  },
};

const STATUS = {
  opened: __('Open'),
  locked: __('Open'),
  closed: __('Closed'),
  merged: __('Merged'),
};

export default {
  components: {
    GlBadge,
    GlIcon,
  },
  mixins: [glFeatureFlagMixin()],
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
    if (!this.iid) return { state: this.initialState };

    if (this.initialState && !badgeState.state) {
      badgeState.state = this.initialState;
    }

    return badgeState;
  },
  computed: {
    badgeVariant() {
      if (this.state === STATUS_OPEN) {
        return 'success';
      } else if (this.state === STATUS_CLOSED) {
        return this.issuableType === TYPE_MERGE_REQUEST ? 'danger' : 'info';
      }
      return 'info';
    },
    badgeText() {
      return STATUS[this.state];
    },
    badgeIcon() {
      const type = this.issuableType || TYPE_MERGE_REQUEST;
      return ICONS[type][this.state];
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
  <gl-badge class="gl-mr-3 gl-align-self-center" :variant="badgeVariant" :aria-label="badgeText">
    <gl-icon :name="badgeIcon" class="gl-badge-icon" />
    <span class="gl-display-none gl-sm-display-block gl-ml-2">{{ badgeText }}</span>
  </gl-badge>
</template>
