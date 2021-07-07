<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { formatTime } from '~/lib/utils/datetime_utility';
import { __, s__, sprintf } from '~/locale';
import eventHub from '../event_hub';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDropdown,
    GlDropdownItem,
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
            'DelayedJobs|Are you sure you want to run %{jobName} immediately? Otherwise this job will run automatically after its timer finishes.',
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
  <gl-dropdown
    v-gl-tooltip
    :title="title"
    :aria-label="title"
    :disabled="isLoading"
    right
    data-container="body"
    data-testid="environment-actions-button"
  >
    <template #button-content>
      <gl-icon name="play" />
      <gl-icon name="chevron-down" />
      <gl-loading-icon v-if="isLoading" size="sm" />
    </template>
    <gl-dropdown-item
      v-for="(action, i) in actions"
      :key="i"
      :disabled="isActionDisabled(action)"
      data-testid="manual-action-link"
      @click="onClickAction(action)"
    >
      <span class="gl-flex-grow-1">{{ action.name }}</span>
      <span v-if="action.scheduledAt" class="gl-text-gray-500 float-right">
        <gl-icon name="clock" />
        {{ remainingTime(action) }}
      </span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
