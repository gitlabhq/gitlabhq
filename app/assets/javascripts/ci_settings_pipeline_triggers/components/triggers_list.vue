<script>
import { GlAvatar, GlAvatarLink, GlBadge, GlButton, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';

export default {
  i18n: {
    copyTrigger: s__('Pipelines|Copy trigger token'),
    editButton: s__('Pipelines|Edit'),
    revokeButton: s__('Pipelines|Revoke trigger'),
    revokeButtonConfirm: s__(
      'Pipelines|By revoking a trigger you will break any processes making use of it. Are you sure?',
    ),
  },
  components: {
    ClipboardButton,
    GlAvatar,
    GlAvatarLink,
    GlBadge,
    GlButton,
    GlTable,
    TimeAgoTooltip,
    TooltipOnTruncate,
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
  data() {
    return {
      areValuesHidden: true,
    };
  },
  fields: [
    {
      key: 'token',
      label: s__('Pipelines|Token'),
      thClass: 'gl-w-60p',
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'description',
      label: s__('Pipelines|Description'),
      thClass: 'gl-w-20p',
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'owner',
      label: s__('Pipelines|Owner'),
      thClass: 'gl-w-5p',
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'lastUsed',
      label: s__('Pipelines|Last Used'),
      thClass: 'gl-w-10p',
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'actions',
      label: __('Actions'),
      tdClass: 'gl-text-right gl-white-space-nowrap',
      thClass: `gl-text-right gl-w-5p`,
    },
  ],
  computed: {
    valuesButtonText() {
      return this.areValuesHidden ? __('Reveal values') : __('Hide values');
    },
    hasTriggers() {
      return this.triggers.length;
    },
    maskedToken() {
      return '*'.repeat(47);
    },
  },
  mounted() {
    const revealButton = document.querySelector('[data-testid="reveal-hide-values-button"]');
    if (revealButton) {
      if (this.triggers.length === 0) {
        revealButton.style.display = 'none';
      }

      revealButton.addEventListener('click', () => {
        this.toggleHiddenState(revealButton);
      });
    }
  },
  methods: {
    toggleHiddenState(element) {
      this.areValuesHidden = !this.areValuesHidden;
      element.innerText = this.valuesButtonText;
    },
  },
};
</script>

<template>
  <div>
    <gl-table
      v-if="hasTriggers"
      :fields="$options.fields"
      :items="triggers"
      class="triggers-list gl-mb-0"
      stacked="md"
      responsive
    >
      <template #cell(token)="{ item }">
        <span v-if="!areValuesHidden">{{ item.token }}</span>
        <span v-else>{{ maskedToken }}</span>
        <clipboard-button
          v-if="item.hasTokenExposed"
          :text="item.token"
          data-testid="clipboard-btn"
          :title="$options.i18n.copyTrigger"
          css-class="gl-border-none gl-py-0 gl-px-2"
        />
        <div v-if="!item.canAccessProject" class="gl-display-inline-block gl-ml-3">
          <gl-badge variant="danger">
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
          class="gl-max-w-15 gl-display-inline-flex"
        >
          <div class="gl-flex-grow-1 gl-text-truncate">{{ item.description }}</div>
        </tooltip-on-truncate>
      </template>
      <template #cell(owner)="{ item }">
        <span class="trigger-owner sr-only">{{ item.owner.name }}</span>
        <gl-avatar-link
          v-if="item.owner"
          v-gl-tooltip
          :href="item.owner.path"
          :title="item.owner.name"
        >
          <gl-avatar :size="24" :src="item.owner.avatarUrl" />
        </gl-avatar-link>
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
          category="tertiary"
          data-testid="edit-btn"
          :href="item.editProjectTriggerPath"
        />
        <gl-button
          :title="$options.i18n.revokeButton"
          :aria-label="$options.i18n.revokeButton"
          icon="remove"
          category="tertiary"
          :data-confirm="$options.i18n.revokeButtonConfirm"
          data-method="delete"
          data-confirm-btn-variant="danger"
          rel="nofollow"
          data-testid="trigger_revoke_button"
          :href="item.projectTriggerPath"
        />
      </template>
    </gl-table>
    <div v-else class="gl-new-card-empty gl-px-5 gl-py-4" data-testid="no_triggers_content">
      {{ s__('Pipelines|No triggers have been created yet. Add one using the form above.') }}
    </div>
  </div>
</template>
