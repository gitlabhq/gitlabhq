<script>
import { GlLoadingIcon, GlButton, GlEmptyState } from '@gitlab/ui';
import EMPTY_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-catalog-md.svg';
import { s__, sprintf } from '~/locale';
import SelectGroupRow from '~/import/offline_transfer/components/select_group_row.vue';

export default {
  name: 'SelectGroupsTab',
  components: { GlLoadingIcon, GlButton, SelectGroupRow, GlEmptyState },
  props: {
    groups: {
      type: Array,
      required: true,
    },
    selectedIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['toggle', 'select-all', 'deselect-all'],
  computed: {
    allSelected() {
      return this.groups.length > 0 && this.selectedIds.length === this.groups.length;
    },
    noneSelected() {
      return this.selectedIds.length === 0;
    },
    countText() {
      return sprintf(s__('OfflineTransferExport|%{selectedCount} of %{totalCount} selected'), {
        selectedCount: this.selectedIds.length,
        totalCount: this.groups.length,
      });
    },
  },
  methods: {
    isChecked(id) {
      return this.selectedIds.includes(id);
    },
  },

  i18n: {
    SELECT_ALL: s__('OfflineTransferExport|Select all'),
    DESELECT_ALL: s__('OfflineTransferExport|Deselect all'),
    EMPTY_TITLE: s__('OfflineTransferExport|You have no groups available to export'),
  },
  EMPTY_SVG_URL,
};
</script>

<template>
  <gl-loading-icon v-if="loading" size="lg" class="gl-mt-5" />
  <gl-empty-state
    v-else-if="groups.length === 0"
    :svg-path="$options.EMPTY_SVG_URL"
    :svg-height="150"
    :title="$options.i18n.EMPTY_TITLE"
  />
  <div v-else>
    <div class="gl-flex gl-items-center gl-justify-between gl-py-3">
      <span class="gl-font-semibold" data-testid="selected-count">{{ countText }}</span>
      <div class="gl-flex gl-gap-3">
        <gl-button
          variant="link"
          data-testid="select-all"
          :disabled="allSelected"
          @click="$emit('select-all')"
        >
          {{ $options.i18n.SELECT_ALL }}
        </gl-button>
        <gl-button
          variant="link"
          data-testid="deselect-all"
          :disabled="noneSelected"
          @click="$emit('deselect-all')"
        >
          {{ $options.i18n.DESELECT_ALL }}
        </gl-button>
      </div>
    </div>
    <ul class="gl-m-0 gl-list-none gl-p-0">
      <select-group-row
        v-for="group in groups"
        :key="group.id"
        :name="group.fullName"
        :description="group.description"
        :avatar-url="group.avatarUrl"
        :checked="isChecked(group.id)"
        @toggle="$emit('toggle', group)"
      />
    </ul>
  </div>
</template>
