<script>
import { GlIcon, GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import mrEventHub from '../eventhub';

const CLASSES = {
  opened: 'status-box-open',
  closed: 'status-box-mr-closed',
  merged: 'status-box-mr-merged',
};

const STATUS = {
  opened: [__('Open'), 'issue-open-m'],
  closed: [__('Closed'), 'close'],
  merged: [__('Merged'), 'git-merge'],
};

export default {
  components: {
    GlIcon,
    GlSprintf,
    GlLink,
  },
  props: {
    initialState: {
      type: String,
      required: true,
    },
    initialIsReverted: {
      type: Boolean,
      required: true,
    },
    initialRevertedPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      state: this.initialState,
      isReverted: this.initialIsReverted,
      revertedPath: this.initialRevertedPath,
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
    updateState({ state, reverted, revertedPath }) {
      this.state = state;
      this.reverted = reverted;
      this.revertedPath = revertedPath;
    },
  },
};
</script>

<template>
  <div :class="statusBoxClass" class="issuable-status-box status-box">
    <gl-icon
      :name="statusIconName"
      class="gl-display-block gl-display-sm-none!"
      data-testid="status-icon"
    />
    <span class="gl-display-none gl-display-sm-block">
      <gl-sprintf v-if="isReverted" :message="__('Merged (%{linkStart}reverted%{linkEnd})')">
        <template #link="{ content }">
          <gl-link
            :href="revertedPath"
            class="gl-reset-color! gl-text-decoration-underline"
            data-testid="reverted-link"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
      <template v-else>{{ statusHumanName }}</template>
    </span>
  </div>
</template>
