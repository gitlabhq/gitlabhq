<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapState } from 'vuex';
import { __ } from '~/locale';
import GLTerminal from '~/terminal/terminal';
import { RUNNING, STOPPING } from '../../stores/modules/terminal/constants';
import { isStartingStatus } from '../../stores/modules/terminal/utils';
import TerminalControls from './terminal_controls.vue';

export default {
  components: {
    GlLoadingIcon,
    TerminalControls,
  },
  props: {
    terminalPath: {
      type: String,
      required: false,
      default: '',
    },
    status: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      glterminal: null,
      canScrollUp: false,
      canScrollDown: false,
    };
  },
  computed: {
    ...mapState(['panelResizing']),
    loadingText() {
      if (isStartingStatus(this.status)) {
        return __('Starting...');
      } else if (this.status === STOPPING) {
        return __('Stopping...');
      }

      return '';
    },
  },
  watch: {
    panelResizing() {
      if (!this.panelResizing && this.glterminal) {
        this.glterminal.fit();
      }
    },
    status() {
      this.refresh();
    },
    terminalPath() {
      this.refresh();
    },
  },
  beforeDestroy() {
    this.destroyTerminal();
  },
  methods: {
    refresh() {
      if (this.status === RUNNING && this.terminalPath) {
        this.createTerminal();
      } else if (this.status === STOPPING) {
        this.stopTerminal();
      }
    },
    createTerminal() {
      this.destroyTerminal();
      this.glterminal = new GLTerminal(this.$refs.terminal);
      this.glterminal.addScrollListener(({ canScrollUp, canScrollDown }) => {
        this.canScrollUp = canScrollUp;
        this.canScrollDown = canScrollDown;
      });
    },
    destroyTerminal() {
      if (this.glterminal) {
        this.glterminal.dispose();
        this.glterminal = null;
      }
    },
    stopTerminal() {
      if (this.glterminal) {
        this.glterminal.disable();
      }
    },
  },
};
</script>

<template>
  <div class="d-flex flex-column flex-fill min-height-0 pr-3">
    <div class="top-bar d-flex border-left-0 align-items-center">
      <div v-if="loadingText" data-qa-selector="loading_container">
        <gl-loading-icon size="sm" :inline="true" />
        <span>{{ loadingText }}</span>
      </div>
      <terminal-controls
        v-if="glterminal"
        class="ml-auto"
        :can-scroll-up="canScrollUp"
        :can-scroll-down="canScrollDown"
        @scroll-up="glterminal.scrollToTop()"
        @scroll-down="glterminal.scrollToBottom()"
      />
    </div>
    <div class="terminal-wrapper d-flex flex-fill min-height-0">
      <div
        ref="terminal"
        class="ide-terminal-trace flex-fill min-height-0 w-100"
        :data-project-path="terminalPath"
        data-qa-selector="terminal_screen"
      ></div>
    </div>
  </div>
</template>
