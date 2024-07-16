<script>
import { GlAvatar, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  name: 'GroupItem',
  components: {
    GlAvatar,
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
    <div v-else class="gl-flex gl-items-center gl-gap-3 gl-grow">
      <gl-avatar
        :alt="fullName"
        :entity-name="fullName"
        :size="32"
        :src="avatarUrl"
        fallback-on-error
      />
      <span class="gl-flex gl-flex-col">
        <span class="gl-font-bold">{{ fullName }}</span>
        <span class="gl-text-gray-600">@{{ name }}</span>
      </span>
    </div>

    <gl-button
      v-if="canDelete"
      v-gl-tooltip="deleteButtonLabel"
      icon="remove"
      :aria-label="deleteButtonLabel"
      category="tertiary"
      @click="$emit('delete', data.id)"
    />
  </div>
</template>
