<script>
import { GlButton, GlTooltipDirective, GlLoadingIcon } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import eventHub from '../event_hub';
import Icon from '../../vue_shared/components/icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    Icon,
    GlCountdown,
    GlButton,
    GlLoadingIcon,
  },
  props: {
    actions: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    onClickAction(action) {
      if (action.scheduled_at) {
        const confirmationMessage = sprintf(
          s__(
            "DelayedJobs|Are you sure you want to run %{jobName} immediately? Otherwise this job will run automatically after it's timer finishes.",
          ),
          { jobName: action.name },
        );
        // https://gitlab.com/gitlab-org/gitlab-ce/issues/52156
        // eslint-disable-next-line no-alert
        if (!window.confirm(confirmationMessage)) {
          return;
        }
      }

      this.isLoading = true;

      eventHub.$emit('postAction', action.path);
    },

    isActionDisabled(action) {
      if (action.playable === undefined) {
        return false;
      }

      return !action.playable;
    },
  },
};
</script>
<template>
  <div class="btn-group">
    <gl-button
      v-gl-tooltip
      :disabled="isLoading"
      class="dropdown-new btn btn-default js-pipeline-dropdown-manual-actions"
      title="Manual job"
      data-toggle="dropdown"
      aria-label="Manual job"
    >
      <icon name="play" class="icon-play" /> <i class="fa fa-caret-down" aria-hidden="true"> </i>
      <gl-loading-icon v-if="isLoading" />
    </gl-button>

    <ul class="dropdown-menu dropdown-menu-right">
      <li v-for="action in actions" :key="action.path">
        <gl-button
          :class="{ disabled: isActionDisabled(action) }"
          :disabled="isActionDisabled(action)"
          class="js-pipeline-action-link no-btn btn"
          @click="onClickAction(action)"
        >
          {{ action.name }}
          <span v-if="action.scheduled_at" class="pull-right">
            <icon name="clock" />
            <gl-countdown :end-date-string="action.scheduled_at" />
          </span>
        </gl-button>
      </li>
    </ul>
  </div>
</template>
