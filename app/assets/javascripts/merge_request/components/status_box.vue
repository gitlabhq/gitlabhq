<script>
import { GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import mrEventHub from '../eventhub';

const CLASSES = {
  opened: 'status-box-open',
  locked: 'status-box-open',
  closed: 'status-box-mr-closed',
  merged: 'status-box-mr-merged',
};

const STATUS = {
  opened: [__('Open'), 'issue-open-m'],
  locked: [__('Open'), 'issue-open-m'],
  closed: [__('Closed'), 'close'],
  merged: [__('Merged'), 'git-merge'],
};

export default {
  components: {
    GlIcon,
  },
  props: {
    initialState: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      state: this.initialState,
    };
  },
  computed: {
    statusBoxClass() {
      return CLASSES[this.state];
    },
    statusHumanName() {
      return STATUS[this.state][0];
    },
    statusIconName() {
      return STATUS[this.state][1];
    },
  },
  created() {
    mrEventHub.$on('mr.state.updated', this.updateState);
  },
  beforeDestroy() {
    mrEventHub.$off('mr.state.updated', this.updateState);
  },
  methods: {
    updateState({ state }) {
      this.state = state;
    },
  },
};
</script>

<template>
  <div :class="statusBoxClass" class="issuable-status-box status-box">
    <gl-icon
      :name="statusIconName"
      class="gl-display-block gl-sm-display-none!"
      data-testid="status-icon"
    />
    <span class="gl-display-none gl-sm-display-block">
      {{ statusHumanName }}
    </span>
  </div>
</template>
