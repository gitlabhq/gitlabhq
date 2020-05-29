<script>
import { throttle } from 'lodash';
import { GlTooltipDirective, GlLoadingIcon } from '@gitlab/ui';
import { mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import {
  MSG_TERMINAL_SYNC_CONNECTING,
  MSG_TERMINAL_SYNC_UPLOADING,
  MSG_TERMINAL_SYNC_RUNNING,
} from '../../stores/modules/terminal_sync/messages';

export default {
  components: {
    Icon,
    GlLoadingIcon,
  },
  directives: {
    'gl-tooltip': GlTooltipDirective,
  },
  data() {
    return { isLoading: false };
  },
  computed: {
    ...mapState('terminalSync', ['isError', 'isStarted', 'message']),
    ...mapState('terminalSync', {
      isLoadingState: 'isLoading',
    }),
    status() {
      if (this.isLoading) {
        return {
          icon: '',
          text: this.isStarted ? MSG_TERMINAL_SYNC_UPLOADING : MSG_TERMINAL_SYNC_CONNECTING,
        };
      } else if (this.isError) {
        return {
          icon: 'warning',
          text: this.message,
        };
      } else if (this.isStarted) {
        return {
          icon: 'mobile-issue-close',
          text: MSG_TERMINAL_SYNC_RUNNING,
        };
      }

      return null;
    },
  },
  watch: {
    // We want to throttle the `isLoading` updates so that
    // the user actually sees an indicator that changes are sent.
    isLoadingState: throttle(function watchIsLoadingState(val) {
      this.isLoading = val;
    }, 150),
  },
  created() {
    this.isLoading = this.isLoadingState;
  },
};
</script>

<template>
  <div
    v-if="status"
    v-gl-tooltip
    :title="status.text"
    role="note"
    class="d-flex align-items-center"
  >
    <span>{{ __('Terminal') }}:</span>
    <span class="square s16 d-flex-center ml-1" :aria-label="status.text">
      <gl-loading-icon v-if="isLoading" inline size="sm" class="d-flex-center" />
      <icon v-else-if="status.icon" :name="status.icon" :size="16" />
    </span>
  </div>
</template>
