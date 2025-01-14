<script>
import { GlIcon, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { formatTime } from '~/lib/utils/datetime_utility';
import { __, s__, sprintf } from '~/locale';
import eventHub from '../event_hub';
import actionMutation from '../graphql/mutations/action.mutation.graphql';

export default {
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
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
    actionItems() {
      return this.actions.map((actionItem) => ({
        text: actionItem.name,
        action: () => this.onClickAction(actionItem),
        extraAttrs: {
          disabled: this.isActionDisabled(actionItem),
        },
        ...actionItem,
      }));
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
  <gl-disclosure-dropdown
    :toggle-text="title"
    :title="title"
    :loading="isLoading"
    :aria-label="title"
    :items="actionItems"
    icon="play"
    size="small"
    text-sr-only
    right
    data-container="body"
    data-testid="environment-actions-button"
  >
    <gl-disclosure-dropdown-item
      v-for="item in actionItems"
      :key="item.name"
      :item="item"
      data-testid="manual-action-link"
    >
      <template #list-item>
        <span class="gl-grow">{{ item.text }}</span>
        <span v-if="item.scheduledAt" class="gl-float-right gl-text-subtle">
          <gl-icon name="clock" />
          {{ remainingTime(item) }}
        </span>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
