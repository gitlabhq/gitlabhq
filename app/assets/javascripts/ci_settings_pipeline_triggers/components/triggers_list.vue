<script>
import {
  GlAvatar,
  GlAvatarLink,
  GlBadge,
  GlButton,
  GlTable,
  GlTooltipDirective,
  GlModalDirective,
} from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { TYPENAME_CI_TRIGGER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createAlert } from '~/alert';
import updatePipelineTriggerMutation from '../graphql/update_pipeline_trigger.mutation.graphql';
import EditTriggerModal from './edit_trigger_modal.vue';

export default {
  i18n: {
    copyTrigger: s__('Pipelines|Copy trigger token'),
    editButton: s__('Pipelines|Edit'),
    revokeButton: s__('Pipelines|Revoke trigger'),
    revokeButtonConfirm: s__(
      'Pipelines|By revoking a trigger token you will break any processes making use of it. Are you sure?',
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
    EditTriggerModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  props: {
    initTriggers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      triggers: cloneDeep(this.initTriggers),
      areValuesHidden: true,
      showModal: false,
      currentTrigger: null,
    };
  },
  fields: [
    {
      key: 'token',
      label: s__('Pipelines|Token'),
      thClass: 'gl-w-10/20',
      tdClass: '!gl-align-middle',
    },
    {
      key: 'description',
      label: s__('Pipelines|Description'),
      thClass: 'gl-w-4/20',
      tdClass: '!gl-align-middle',
    },
    {
      key: 'owner',
      label: s__('Pipelines|Owner'),
      thClass: 'gl-w-1/20',
      tdClass: '!gl-align-middle',
    },
    {
      key: 'lastUsed',
      label: s__('Pipelines|Last Used'),
      thClass: 'gl-w-2/20',
      tdClass: '!gl-align-middle',
    },
    {
      key: 'expireTime',
      label: s__('Pipelines|Expires'),
      thClass: 'gl-w-2/20',
      tdClass: '!gl-align-middle',
    },
    {
      key: 'actions',
      label: __('Actions'),
      tdClass: 'gl-text-right gl-whitespace-nowrap',
      thAlignRight: true,
      thClass: `gl-w-1/20`,
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
  watch: {
    showModal(val) {
      if (!val) {
        this.currentTrigger = null;
      }
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
    handleEditClick(item) {
      this.currentTrigger = item;
      this.showModal = true;
    },
    async onSubmit(newTrigger) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updatePipelineTriggerMutation,
          variables: {
            id: convertToGraphQLId(TYPENAME_CI_TRIGGER, newTrigger.id),
            description: newTrigger.description,
          },
        });

        if (data.pipelineTriggerUpdate?.errors?.length) {
          createAlert({ message: data.pipelineTriggerUpdate.errors[0] });
        } else {
          this.onSuccess(data.pipelineTriggerUpdate.pipelineTrigger);
        }
      } catch {
        createAlert({
          message: s__(
            'Pipelines|An error occurred while updating the trigger token. Please try again.',
          ),
        });
      }
    },
    onSuccess(newTrigger) {
      const id = getIdFromGraphQLId(newTrigger.id);

      const triggerToUpdate = this.triggers.find((trigger) => trigger.id === id);

      if (triggerToUpdate) {
        triggerToUpdate.description = newTrigger.description;
      }
    },
  },
  editModalId: 'edit-trigger-modal',
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
        <span v-if="!areValuesHidden" class="gl-font-monospace">{{ item.token }}</span>
        <span v-else>{{ maskedToken }}</span>
        <clipboard-button
          v-if="item.hasTokenExposed"
          :text="item.token"
          category="tertiary"
          data-testid="clipboard-btn"
          :title="$options.i18n.copyTrigger"
          css-class="gl-border-none gl-py-0 gl-px-2"
        />
        <div v-if="!item.canAccessProject" class="gl-ml-3 gl-inline-block">
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
          class="gl-inline-flex gl-max-w-15"
        >
          <div class="gl-grow gl-truncate">{{ item.description }}</div>
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
      <template #cell(expireTime)="{ item }">
        <time-ago-tooltip v-if="item.expiresAt" :time="item.expiresAt" />
        <span v-else>{{ __('Never') }}</span>
      </template>
      <template #cell(actions)="{ item }">
        <gl-button
          v-gl-modal="$options.editModalId"
          :title="s__('Pipelines|Edit')"
          icon="pencil"
          category="tertiary"
          data-testid="edit-btn"
          :aria-label="__('Edit trigger token')"
          @click="handleEditClick(item)"
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
    <div v-else class="gl-text-subtle" data-testid="no_triggers_content">
      {{ s__('Pipelines|No trigger tokens have been created yet. Add one using the form above.') }}
    </div>
    <edit-trigger-modal
      v-if="currentTrigger"
      :modal-id="$options.editModalId"
      :trigger="currentTrigger"
      @submit="onSubmit"
    />
  </div>
</template>
