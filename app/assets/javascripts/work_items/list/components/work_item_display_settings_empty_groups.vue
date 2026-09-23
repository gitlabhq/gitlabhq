<script>
import { GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { persistMetadataPreference, alertPreferenceError } from '../display_settings_preferences';

export default {
  name: 'WorkItemDisplaySettingsEmptyGroups',
  components: {
    GlDisclosureDropdownItem,
    GlToggle,
  },
  mixins: [InternalEvents.mixin()],
  i18n: {
    showEmptyGroups: s__('WorkItems|Show empty groups'),
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemTypeId: {
      type: String,
      required: true,
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
    isSavedView: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['update-settings'],
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    showEmptyGroups() {
      return this.namespacePreferences.showEmptyGroups ?? true;
    },
  },
  methods: {
    async toggleShowEmptyGroups() {
      const showEmptyGroups = !this.showEmptyGroups;
      const input = { ...this.namespacePreferences, showEmptyGroups };

      this.trackEvent('configure_columns_on_work_item_board', {
        label: showEmptyGroups ? 'show_empty_groups' : 'hide_empty_groups',
      });

      if (this.isSavedView) {
        this.$emit('update-settings', input);
        return;
      }

      this.isLoading = true;

      try {
        await persistMetadataPreference({
          apolloClient: this.$apollo,
          namespace: this.fullPath,
          workItemTypeId: this.workItemTypeId,
          userPreferencesOnly: false,
          displaySettings: input,
          sort: this.sortKey,
        });
      } catch (error) {
        alertPreferenceError(error);
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <ul class="gl-m-0 gl-list-none gl-px-2 gl-py-1" data-testid="display-settings-empty-groups">
    <gl-disclosure-dropdown-item class="work-item-dropdown-toggle" @action="toggleShowEmptyGroups">
      <template #list-item>
        <gl-toggle
          :value="showEmptyGroups"
          :label="$options.i18n.showEmptyGroups"
          class="gl-w-full gl-justify-between"
          label-position="left"
          :is-loading="isLoading"
        />
      </template>
    </gl-disclosure-dropdown-item>
  </ul>
</template>
