<script>
import { GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';

export const statusBoxState = Vue.observable({
  state: '',
  updateStatus: null,
});

const CLASSES = {
  opened: 'status-box-open',
  merge_request_opened: 'badge-success',
  locked: 'status-box-open',
  merge_request_locked: 'badge-success',
  closed: 'status-box-mr-closed',
  merge_request_closed: 'badge-danger',
  merged: 'badge-info',
};

const STATUS = {
  opened: [__('Open'), 'issue-open-m'],
  locked: [__('Open'), 'issue-open-m'],
  closed: [__('Closed'), 'issue-close'],
  merged: [__('Merged'), 'git-merge'],
};

export default {
  components: {
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
    if (this.initialState) {
      statusBoxState.state = this.initialState;
    }

    return statusBoxState;
  },
  computed: {
    isMergeRequest() {
      return this.issuableType === 'merge_request' && this.glFeatures.updatedMrHeader;
    },
    statusBoxClass() {
      return [
        CLASSES[`${this.issuableType}_${this.state}`] || CLASSES[this.state],
        {
          'badge badge-pill gl-badge gl-mr-3': this.isMergeRequest,
          'issuable-status-box status-box': !this.isMergeRequest,
        },
      ];
    },
    statusHumanName() {
      return (STATUS[`${this.issuableType}_${this.state}`] || STATUS[this.state])[0];
    },
    statusIconName() {
      return (STATUS[`${this.issuableType}_${this.state}`] || STATUS[this.state])[1];
    },
  },
  created() {
    if (!statusBoxState.updateStatus) {
      statusBoxState.updateStatus = this.fetchState;
    }
  },
  beforeDestroy() {
    if (statusBoxState.updateStatus && this.query) {
      statusBoxState.updateStatus = null;
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

      statusBoxState.state = data?.workspace?.issuable?.state;
    },
  },
};
</script>

<template>
  <div :class="statusBoxClass">
    <gl-icon
      v-if="!isMergeRequest"
      :name="statusIconName"
      class="gl-display-block gl-sm-display-none!"
    />
    <span :class="{ 'gl-display-none gl-sm-display-block': !isMergeRequest }">
      {{ statusHumanName }}
    </span>
  </div>
</template>
