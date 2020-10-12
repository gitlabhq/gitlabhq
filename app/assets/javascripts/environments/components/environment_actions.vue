<script>
import { GlButton, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { formatTime } from '~/lib/utils/datetime_utility';
import eventHub from '../event_hub';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
  },
  props: {
    actions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    title() {
      return __('Deploy to...');
    },
  },
  methods: {
    onClickAction(action) {
      if (action.scheduledAt) {
        const confirmationMessage = sprintf(
          s__(
            "DelayedJobs|Are you sure you want to run %{jobName} immediately? Otherwise this job will run automatically after it's timer finishes.",
          ),
          { jobName: action.name },
        );
        // https://gitlab.com/gitlab-org/gitlab-foss/issues/52156
        // eslint-disable-next-line no-alert
        if (!window.confirm(confirmationMessage)) {
          return;
        }
      }

      this.isLoading = true;

      eventHub.$emit('postAction', { endpoint: action.playPath });
    },

    isActionDisabled(action) {
      if (action.playable === undefined) {
        return false;
      }

      return !action.playable;
    },

    remainingTime(action) {
      const remainingMilliseconds = new Date(action.scheduledAt).getTime() - Date.now();
      return formatTime(Math.max(0, remainingMilliseconds));
    },
  },
};
</script>
<template>
  <div class="btn-group" role="group">
    <gl-button
      v-gl-tooltip
      :title="title"
      :aria-label="title"
      :disabled="isLoading"
      class="dropdown dropdown-new js-environment-actions-dropdown"
      data-container="body"
      data-toggle="dropdown"
      data-testid="environment-actions-button"
    >
      <span>
        <gl-icon name="play" />
        <gl-icon name="chevron-down" />
        <gl-loading-icon v-if="isLoading" />
      </span>
    </gl-button>

    <ul class="dropdown-menu dropdown-menu-right">
      <li v-for="(action, i) in actions" :key="i" class="gl-display-flex">
        <gl-button
          :class="{ disabled: isActionDisabled(action) }"
          :disabled="isActionDisabled(action)"
          variant="link"
          class="js-manual-action-link gl-flex-fill-1"
          @click="onClickAction(action)"
        >
          <span class="gl-flex-fill-1">{{ action.name }}</span>
          <span v-if="action.scheduledAt" class="text-secondary float-right">
            <gl-icon name="clock" />
            {{ remainingTime(action) }}
          </span>
        </gl-button>
      </li>
    </ul>
  </div>
</template>
