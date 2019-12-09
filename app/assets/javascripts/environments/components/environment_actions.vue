<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { formatTime } from '~/lib/utils/datetime_utility';
import Icon from '~/vue_shared/components/icon.vue';
import eventHub from '../event_hub';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
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
    <button
      v-tooltip
      :title="title"
      :aria-label="title"
      :disabled="isLoading"
      type="button"
      class="dropdown btn btn-default dropdown-new js-environment-actions-dropdown"
      data-container="body"
      data-toggle="dropdown"
    >
      <span>
        <icon name="play" />
        <icon name="chevron-down" />
        <gl-loading-icon v-if="isLoading" />
      </span>
    </button>

    <ul class="dropdown-menu dropdown-menu-right">
      <li v-for="(action, i) in actions" :key="i">
        <button
          :class="{ disabled: isActionDisabled(action) }"
          :disabled="isActionDisabled(action)"
          type="button"
          class="js-manual-action-link no-btn btn d-flex align-items-center"
          @click="onClickAction(action)"
        >
          <span class="flex-fill">{{ action.name }}</span>
          <span v-if="action.scheduledAt" class="text-secondary">
            <icon name="clock" />
            {{ remainingTime(action) }}
          </span>
        </button>
      </li>
    </ul>
  </div>
</template>
