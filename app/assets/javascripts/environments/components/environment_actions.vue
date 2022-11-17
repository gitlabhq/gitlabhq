<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { formatTime } from '~/lib/utils/datetime_utility';
import { __, s__, sprintf } from '~/locale';
import eventHub from '../event_hub';
import actionMutation from '../graphql/mutations/action.mutation.graphql';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
  },
  props: {
    actions: {
      type: Array,
      required: false,
      default: () => [],
    },
    graphql: {
      type: Boolean,
      required: false,
      default: false,
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
    async onClickAction(action) {
      if (action.scheduledAt) {
        const confirmationMessage = sprintf(
          s__(
            'DelayedJobs|Are you sure you want to run %{jobName} immediately? Otherwise this job will run automatically after its timer finishes.',
          ),
          { jobName: action.name },
        );

        const confirmed = await confirmAction(confirmationMessage);

        if (!confirmed) {
          return;
        }
      }

      this.isLoading = true;

      if (this.graphql) {
        await this.$apollo.mutate({ mutation: actionMutation, variables: { action } });
        this.isLoading = false;
      } else {
        eventHub.$emit('postAction', { endpoint: action.playPath });
      }
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
    :text="title"
    :title="title"
    :loading="isLoading"
    :aria-label="title"
    icon="play"
    text-sr-only
    right
    data-container="body"
    data-testid="environment-actions-button"
  >
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
