<script>
import { GlTable, GlButton, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  i18n: {
    editButton: s__('Pipelines|Edit'),
    revokeButton: s__('Pipelines|Revoke'),
  },
  components: {
    GlTable,
    GlButton,
    GlBadge,
    ClipboardButton,
    TooltipOnTruncate,
    UserAvatarLink,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    triggers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  fields: [
    {
      key: 'token',
      label: s__('Pipelines|Token'),
    },
    {
      key: 'description',
      label: s__('Pipelines|Description'),
    },
    {
      key: 'owner',
      label: s__('Pipelines|Owner'),
    },
    {
      key: 'lastUsed',
      label: s__('Pipelines|Last Used'),
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right gl-white-space-nowrap',
    },
  ],
};
</script>

<template>
  <div>
    <gl-table
      v-if="triggers.length"
      :fields="$options.fields"
      :items="triggers"
      class="triggers-list"
      responsive
    >
      <template #cell(token)="{ item }">
        {{ item.token }}
        <clipboard-button
          v-if="item.hasTokenExposed"
          :text="item.token"
          data-testid="clipboard-btn"
          data-qa-selector="clipboard_button"
          :title="s__('Pipelines|Copy trigger token')"
          css-class="gl-border-none gl-py-0 gl-px-2"
        />
        <div class="label-container">
          <gl-badge v-if="!item.canAccessProject" variant="danger">
            <span
              v-gl-tooltip.viewport
              boundary="viewport"
              :title="s__('Pipelines|Trigger user has insufficient permissions to project')"
              >{{ s__('Pipelines|invalid') }}</span
            >
          </gl-badge>
        </div>
      </template>
      <template #cell(description)="{ item }">
        <tooltip-on-truncate
          :title="item.description"
          truncate-target="child"
          placement="top"
          class="trigger-description gl-display-flex"
        >
          <div class="gl-flex-grow-1 gl-text-truncate">{{ item.description }}</div>
        </tooltip-on-truncate>
      </template>
      <template #cell(owner)="{ item }">
        <span class="trigger-owner sr-only">{{ item.owner.name }}</span>
        <user-avatar-link
          v-if="item.owner"
          :link-href="item.owner.path"
          :img-src="item.owner.avatarUrl"
          :tooltip-text="item.owner.name"
          :img-alt="item.owner.name"
        />
      </template>
      <template #cell(lastUsed)="{ item }">
        <time-ago-tooltip v-if="item.lastUsed" :time="item.lastUsed" />
        <span v-else>{{ __('Never') }}</span>
      </template>
      <template #cell(actions)="{ item }">
        <gl-button
          :title="$options.i18n.editButton"
          :aria-label="$options.i18n.editButton"
          icon="pencil"
          data-testid="edit-btn"
          :href="item.editProjectTriggerPath"
        />
        <gl-button
          :title="$options.i18n.revokeButton"
          :aria-label="$options.i18n.revokeButton"
          icon="remove"
          variant="warning"
          :data-confirm="
            s__(
              'Pipelines|By revoking a trigger you will break any processes making use of it. Are you sure?',
            )
          "
          data-method="delete"
          rel="nofollow"
          class="gl-ml-3"
          data-testid="trigger_revoke_button"
          data-qa-selector="trigger_revoke_button"
          :href="item.projectTriggerPath"
        />
      </template>
    </gl-table>
    <div
      v-else
      data-testid="no_triggers_content"
      data-qa-selector="no_triggers_content"
      class="settings-message gl-text-center gl-mb-3"
    >
      {{ s__('Pipelines|No triggers have been created yet. Add one using the form above.') }}
    </div>
  </div>
</template>
