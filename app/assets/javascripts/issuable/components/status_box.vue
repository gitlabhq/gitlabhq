<script>
import { GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';

export const statusBoxState = Vue.observable({
  state: '',
  updateStatus: null,
});

const CLASSES = {
  opened: 'status-box-open',
  locked: 'status-box-open',
  closed: 'status-box-mr-closed',
  merged: 'status-box-mr-merged',
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
    statusBoxClass() {
      return CLASSES[`${this.issuableType}_${this.state}`] || CLASSES[this.state];
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
  <div :class="statusBoxClass" class="issuable-status-box status-box">
    <gl-icon :name="statusIconName" class="gl-display-block gl-sm-display-none!" />
    <span class="gl-display-none gl-sm-display-block">
      {{ statusHumanName }}
    </span>
  </div>
</template>
