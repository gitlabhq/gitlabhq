<script>
import { GlDrawer } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import WorkItemDisplaySettingsSort from './work_item_display_settings_sort.vue';
import WorkItemDisplaySettingsMetadata from './work_item_display_settings_metadata.vue';
import WorkItemDisplaySettingsUserPreferences from './work_item_display_settings_user_preferences.vue';

export default {
  name: 'WorkItemDisplaySettingsDrawer',
  components: {
    GlDrawer,
    WorkItemDisplaySettingsSort,
    WorkItemDisplaySettingsMetadata,
    WorkItemDisplaySettingsUserPreferences,
  },
  i18n: {
    title: s__('WorkItems|Display'),
  },
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemTypeId: {
      type: String,
      required: true,
    },
    sortOptions: {
      type: Array,
      required: false,
      default: () => [],
    },
    sortKey: {
      type: String,
      required: false,
      default: '',
    },
    namespacePreferences: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    commonPreferences: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    isServiceDeskList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['close', 'sort', 'update-settings'],
  computed: {
    hasSortOptions() {
      return this.sortOptions.length > 0;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSort(newSortKey) {
      this.$emit('sort', newSortKey);
    },
    onSettingsUpdate(input) {
      this.$emit('update-settings', input);
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer
    :open="open"
    :z-index="$options.DRAWER_Z_INDEX"
    class="work-item-display-settings-drawer"
    data-testid="display-settings-drawer"
    @close="onClose"
  >
    <template #title>
      <h2 class="gl-my-0 gl-text-size-h2 gl-leading-24">{{ $options.i18n.title }}</h2>
    </template>
    <template #default>
      <div class="gl-flex gl-h-full gl-flex-col !gl-p-0">
        <work-item-display-settings-sort
          v-if="hasSortOptions"
          :sort-options="sortOptions"
          :sort-key="sortKey"
          class="gl-px-5 gl-pb-4 gl-pt-5"
          @sort="onSort"
        />
        <div :class="{ 'gl-border-t gl-pt-5': hasSortOptions }" class="gl-p-2">
          <work-item-display-settings-metadata
            :namespace-preferences="namespacePreferences"
            :full-path="fullPath"
            :is-group="isGroup"
            :is-service-desk-list="isServiceDeskList"
            :work-item-type-id="workItemTypeId"
            :sort-key="sortKey"
            @update-settings="onSettingsUpdate"
          />
          <work-item-display-settings-user-preferences
            class="!gl-border-t gl-mt-auto gl-pb-5 gl-pt-5"
            :common-preferences="commonPreferences"
            :full-path="fullPath"
            :work-item-type-id="workItemTypeId"
          />
        </div>
      </div>
    </template>
  </gl-drawer>
</template>
