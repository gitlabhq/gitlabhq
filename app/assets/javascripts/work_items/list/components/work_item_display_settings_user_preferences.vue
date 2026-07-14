<script>
import { GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import {
  persistSidePanelPreference,
  alertPreferenceError,
} from '~/work_items/list/display_settings_preferences';

export default {
  name: 'WorkItemDisplaySettingsUserPreferences',
  components: {
    GlDisclosureDropdownItem,
    GlToggle,
    HelpPopover,
  },
  mixins: [InternalEvents.mixin()],
  i18n: {
    yourPreferences: s__('WorkItems|Your preferences'),
    openItemsInSidePanel: s__('WorkItems|Open items in side panel'),
    optionsAppliedToAllViews: s__('WorkItems|Options applied to all views'),
  },
  props: {
    commonPreferences: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    fullPath: {
      type: String,
      required: true,
    },
    workItemTypeId: {
      type: String,
      required: true,
    },
    isSavedView: {
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
    shouldOpenItemsInSidePanel() {
      return this.commonPreferences?.shouldOpenItemsInSidePanel ?? true;
    },
  },
  methods: {
    async toggleSidePanelPreference() {
      const isEnabled = this.shouldOpenItemsInSidePanel;

      this.isLoading = true;

      try {
        await persistSidePanelPreference({
          apolloClient: this.$apollo,
          namespace: this.fullPath,
          workItemTypeId: this.workItemTypeId,
          userPreferencesOnly: this.isSavedView,
          shouldOpenItemsInSidePanel: !isEnabled,
        });

        if (isEnabled) {
          this.trackEvent('work_item_drawer_disabled');
        }
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
  <div data-testid="display-settings-user-preferences">
    <div>
      <span class="gl-pl-4">{{ $options.i18n.yourPreferences }}</span>
      <help-popover icon="information-o">
        {{ $options.i18n.optionsAppliedToAllViews }}
      </help-popover>
    </div>
    <ul class="gl-m-0 gl-mt-2 gl-list-none gl-p-0">
      <gl-disclosure-dropdown-item
        class="work-item-dropdown-toggle"
        @action="toggleSidePanelPreference"
      >
        <template #list-item>
          <gl-toggle
            :value="shouldOpenItemsInSidePanel"
            :label="$options.i18n.openItemsInSidePanel"
            class="gl-justify-between"
            label-position="left"
            :is-loading="isLoading"
          />
        </template>
      </gl-disclosure-dropdown-item>
    </ul>
  </div>
</template>
