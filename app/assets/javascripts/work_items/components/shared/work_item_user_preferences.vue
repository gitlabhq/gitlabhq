<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlToggle,
  GlTooltipDirective,
  GlIcon,
} from '@gitlab/ui';
import produce from 'immer';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import updateWorkItemsDisplaySettings from '~/work_items/graphql/update_user_preferences.mutation.graphql';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import getUserWorkItemsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import { WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS, METADATA_KEYS } from '~/work_items/constants';

export default {
  name: 'WorkItemUserPreferences',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlToggle,
    GlIcon,
    HelpPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  inject: ['isSignedIn', 'isGroupIssuesList'],
  i18n: {
    displayOptions: s__('WorkItems|Display options'),
    yourPreferences: s__('WorkItems|Your preferences'),
    openItemsInSidePanel: s__('WorkItems|Open items in side panel'),
    fields: s__('WorkItems|Fields'),
  },
  props: {
    displaySettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    fullPath: {
      type: String,
      required: true,
    },
    isEpicsList: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemTypeId: {
      type: String,
      required: true,
    },
    sortKey: {
      type: String,
      required: true,
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
      return this.displaySettings.commonPreferences?.shouldOpenItemsInSidePanel ?? true;
    },
    hiddenMetadataKeys() {
      return this.displaySettings.namespacePreferences?.hiddenMetadataKeys || [];
    },
    applicableMetadataPreferences() {
      return WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS.filter((item) => {
        if (item.key === METADATA_KEYS.STATUS) {
          return !this.isEpicsList;
        }
        return !this.isGroup || item.isPresentInGroup || this.isGroupIssuesList;
      });
    },
  },
  methods: {
    showDropdown() {
      this.isDropdownVisible = true;
    },
    hideDropdown() {
      this.isDropdownVisible = false;
    },

    async toggleMetadataDisplaySettings(metadataKey) {
      const wasHidden = this.hiddenMetadataKeys.includes(metadataKey);
      const newHiddenKeys = wasHidden
        ? this.hiddenMetadataKeys.filter((key) => key !== metadataKey)
        : [...this.hiddenMetadataKeys, metadataKey];

      const input = {
        hiddenMetadataKeys: newHiddenKeys,
      };

      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemListUserPreference,
          variables: {
            namespace: this.fullPath,
            displaySettings: input,
          },
          optimisticResponse: {
            workItemUserPreferenceUpdate: {
              errors: [],
              userPreferences: {
                displaySettings: {
                  hiddenMetadataKeys: newHiddenKeys,
                },
                sort: this.sortKey,
                __typename: 'WorkItemTypesUserPreference',
              },
              __typename: 'WorkItemUserPreferenceUpdatePayload',
            },
          },
          update: (
            cache,
            {
              data: {
                workItemUserPreferenceUpdate: { userPreferences },
              },
            },
          ) => {
            cache.updateQuery(
              {
                query: getUserWorkItemsPreferences,
                variables: { namespace: this.fullPath, workItemTypeId: this.workItemTypeId },
              },
              (existingData) =>
                produce(existingData, (draftData) => {
                  draftData.currentUser.workItemPreferences = {
                    ...(draftData.currentUser.workItemPreferences ?? {}),
                    displaySettings: userPreferences.displaySettings,
                  };
                }),
            );
          },
        });

        if (!wasHidden) {
          this.trackEvent('work_item_metadata_field_hidden', {
            property: metadataKey,
          });
        }
      } catch (error) {
        createAlert({
          message: __('Something went wrong while saving the preference.'),
          captureError: true,
          error,
        });
      }
    },

    async toggleSidePanelPreference() {
      const isEnabled = this.shouldOpenItemsInSidePanel;

      const input = {
        workItemsDisplaySettings: {
          shouldOpenItemsInSidePanel: !isEnabled,
        },
      };

      this.isLoading = true;

      try {
        await this.$apollo.mutate({
          mutation: updateWorkItemsDisplaySettings,
          variables: { input },
          update: (
            cache,
            {
              data: {
                userPreferencesUpdate: { userPreferences },
              },
            },
          ) => {
            cache.updateQuery(
              {
                query: getUserWorkItemsPreferences,
                variables: { namespace: this.fullPath, workItemTypeId: this.workItemTypeId },
              },
              (existingData) =>
                produce(existingData, (draftData) => {
                  if (draftData?.currentUser?.userPreferences) {
                    draftData.currentUser.userPreferences.workItemsDisplaySettings =
                      userPreferences.workItemsDisplaySettings;
                  }
                }),
            );
          },
        });

        if (isEnabled) {
          this.trackEvent('work_item_drawer_disabled');
        }
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
    class="gl-mt-[10px] @sm/panel:gl-mt-0"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <div class="gl-pt-2">
      <span class="gl-pl-4 gl-text-sm gl-font-bold">{{ $options.i18n.fields }}</span>
      <gl-disclosure-dropdown-item
        v-for="metadata in applicableMetadataPreferences"
        :key="metadata.key"
        class="work-item-dropdown-toggle"
        @action="toggleMetadataDisplaySettings(metadata.key)"
      >
        <template #list-item>
          <div class="gl-flex gl-items-center gl-gap-3">
            <gl-icon :name="metadata.icon" />
            <gl-toggle
              :value="!hiddenMetadataKeys.includes(metadata.key)"
              :label="metadata.label"
              class="gl-w-full gl-justify-between"
              label-position="left"
            />
          </div>
        </template>
      </gl-disclosure-dropdown-item>
    </div>
    <div class="!gl-border-t gl-mt-2 !gl-border-t-gray-300 gl-pt-3">
      <div>
        <span class="gl-pl-4 gl-text-sm gl-font-bold">{{ $options.i18n.yourPreferences }}</span>
        <help-popover icon="information-o">
          {{ s__('WorkItems|Options applied to all views') }}
        </help-popover>
      </div>
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
