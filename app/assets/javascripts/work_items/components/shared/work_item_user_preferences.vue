<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlToggle,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import workItemDisplaySettingsQuery from '~/work_items/graphql/get_user_preferences.query.graphql';
import updateWorkItemsDisplaySettings from '../../graphql/update_user_preferences.mutation.graphql';

export default {
  name: 'WorkItemUserPreferences',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlToggle,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    isSignedIn: {
      default: false,
    },
  },
  i18n: {
    displayOptions: s__('WorkItems|Display options'),
    yourPreferences: s__('WorkItems|Your preferences'),
    openItemsInSidePanel: s__('WorkItems|Open items in side panel'),
  },
  props: {
    displaySettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      isDropdownVisible: false,
      isLoading: false,
    };
  },
  computed: {
    tooltipText() {
      return !this.isDropdownVisible ? this.$options.i18n.displayOptions : '';
    },
    shouldOpenItemsInSidePanel() {
      return this.displaySettings?.shouldOpenItemsInSidePanel ?? true;
    },
  },
  methods: {
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },
    async toggleSidePanelPreference() {
      const newDisplaySettings = {
        ...this.displaySettings,
        shouldOpenItemsInSidePanel: !this.shouldOpenItemsInSidePanel,
      };

      const input = {
        workItemsDisplaySettings: newDisplaySettings,
      };
      this.isLoading = true;
      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemsDisplaySettings,
          variables: {
            input,
          },
          update: (
            cache,
            {
              data: {
                userPreferencesUpdate: { userPreferences },
              },
            },
          ) => {
            cache.updateQuery({ query: workItemDisplaySettingsQuery }, ({ currentUser }) => ({
              currentUser: {
                ...currentUser,
                userPreferences,
              },
            }));
          },
        });
      } catch (error) {
        createAlert({
          message: __('Something went wrong while saving the preference.'),
          captureError: true,
          error,
        });
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="isSignedIn"
    v-gl-tooltip="tooltipText"
    icon="preferences"
    text-sr-only
    :toggle-text="$options.i18n.displayOptions"
    category="primary"
    no-caret
    placement="bottom-end"
    :auto-close="false"
    class="gl-mt-[10px] sm:gl-mt-0"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <div class="gl-mt-2">
      <span class="gl-pl-4 gl-text-sm gl-font-bold">{{ $options.i18n.yourPreferences }}</span>
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
    </div>
  </gl-disclosure-dropdown>
</template>
