<script>
import { GlAvatarLabeled, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  name: 'GroupItem',
  components: {
    GlAvatarLabeled,
    GlButton,
    HiddenGroupsItem: () => import('ee_component/approvals/components/hidden_groups_item.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    deleteButtonLabel() {
      return sprintf(__('Delete %{name}'), { name: this.name });
    },
    fullName() {
      return this.data.fullName || this.data.name;
    },
    name() {
      return this.data.name;
    },
    avatarUrl() {
      return this.data.avatarUrl;
    },
    isHiddenGroups() {
      return this.data.type === 'hidden_groups';
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-gap-3">
    <hidden-groups-item v-if="isHiddenGroups" class="gl-grow" />
    <gl-avatar-labeled
      v-else
      class="gl-grow gl-break-all"
      :entity-name="fullName"
      :label="fullName"
      :sub-label="`@${name}`"
      :size="32"
      shape="rect"
      :src="avatarUrl"
      fallback-on-error
    />

    <gl-button
      v-if="canDelete"
      v-gl-tooltip="deleteButtonLabel"
      icon="remove"
      :aria-label="deleteButtonLabel"
      category="tertiary"
      data-testid="delete-group-btn"
      @click="$emit('delete', data.id)"
    />
  </div>
</template>
