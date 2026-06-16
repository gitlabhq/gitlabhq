<script>
import { GlDisclosureDropdownItem, GlIcon, GlSearchBoxByType, GlToggle } from '@gitlab/ui';
import produce from 'immer';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import getUserWorkItemsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import {
  WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED,
  METADATA_KEYS,
  ROUTES,
} from '~/work_items/constants';

export default {
  name: 'WorkItemDisplaySettingsMetadata',
  components: {
    GlDisclosureDropdownItem,
    GlIcon,
    GlSearchBoxByType,
    GlToggle,
  },
  mixins: [InternalEvents.mixin()],
  i18n: {
    fields: s__('WorkItems|Fields'),
    shown: s__('WorkItems|Shown'),
    hidden: s__('WorkItems|Hidden'),
    searchPlaceholder: s__('WorkItems|Search fields'),
    noFieldsFound: s__('WorkItems|No fields match your search.'),
  },
  props: {
    workItemTypeId: {
      type: String,
      required: true,
    },
    sortKey: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    namespacePreferences: {
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
  emits: ['update-settings'],
  data() {
    return {
      searchQuery: '',
    };
  },
  computed: {
    isSavedView() {
      return this.$route?.name === ROUTES.savedView;
    },
    hiddenMetadataKeys() {
      return this.namespacePreferences?.hiddenMetadataKeys || [];
    },
    applicableMetadataPreferences() {
      return WORK_ITEM_LIST_PREFERENCES_METADATA_FIELDS_SORTED.filter((item) => {
        if (item.key === METADATA_KEYS.STATUS) {
          return !this.isServiceDeskList;
        }
        return !this.isGroup || item.isPresentInGroup;
      });
    },
    filteredMetadataPreferences() {
      const query = this.searchQuery.trim().toLowerCase();
      if (!query) return this.applicableMetadataPreferences;
      return this.applicableMetadataPreferences.filter((item) =>
        item.label.toLowerCase().includes(query),
      );
    },
    shownPreferences() {
      return this.filteredMetadataPreferences.filter(
        (item) => !this.hiddenMetadataKeys.includes(item.key),
      );
    },
    hiddenPreferences() {
      return this.filteredMetadataPreferences.filter((item) =>
        this.hiddenMetadataKeys.includes(item.key),
      );
    },
    noFieldsAvailable() {
      return this.filteredMetadataPreferences.length === 0;
    },
  },
  methods: {
    async toggleMetadataDisplaySettings(metadataKey) {
      const wasHidden = this.hiddenMetadataKeys.includes(metadataKey);
      const newHiddenKeys = wasHidden
        ? this.hiddenMetadataKeys.filter((key) => key !== metadataKey)
        : [...this.hiddenMetadataKeys, metadataKey];

      const input = {
        hiddenMetadataKeys: newHiddenKeys,
      };

      if (this.isSavedView) {
        this.$emit('update-settings', input);
        if (!wasHidden) {
          this.trackEvent('work_item_metadata_field_hidden', {
            property: metadataKey,
          });
        }
        return;
      }

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
                variables: {
                  namespace: this.fullPath,
                  workItemTypeId: this.workItemTypeId,
                  userPreferencesOnly: this.isSavedView,
                },
              },
              (existingData) =>
                produce(existingData, (draftData) => {
                  if (draftData?.currentUser) {
                    draftData.currentUser.workItemPreferences = {
                      ...(draftData?.currentUser?.workItemPreferences ?? {}),
                      displaySettings: userPreferences.displaySettings,
                    };
                  }
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
  },
};
</script>

<template>
  <div data-testid="display-settings-metadata" class="gl-pb-3">
    <span class="gl-pl-4">{{ $options.i18n.fields }}</span>
    <gl-search-box-by-type
      v-model="searchQuery"
      :placeholder="$options.i18n.searchPlaceholder"
      class="gl-mx-3 gl-mt-3"
      data-testid="display-settings-metadata-search"
    />
    <p
      v-if="noFieldsAvailable"
      data-testid="no-fields-found"
      class="gl-mb-0 gl-mt-3 gl-px-4 gl-text-sm gl-text-subtle"
    >
      {{ $options.i18n.noFieldsFound }}
    </p>
    <div v-if="shownPreferences.length" data-testid="shown-preferences" class="gl-mt-4">
      <span class="gl-pl-4 gl-text-sm gl-font-bold">{{ $options.i18n.shown }}</span>
      <ul class="gl-m-0 gl-mt-2 gl-list-none gl-p-0">
        <gl-disclosure-dropdown-item
          v-for="metadata in shownPreferences"
          :key="metadata.key"
          class="work-item-dropdown-toggle"
          @action="toggleMetadataDisplaySettings(metadata.key)"
        >
          <template #list-item>
            <div class="gl-flex gl-items-center gl-gap-3">
              <gl-icon :name="metadata.icon" />
              <gl-toggle
                :value="true"
                :label="metadata.label"
                class="gl-w-full gl-justify-between"
                label-position="left"
              />
            </div>
          </template>
        </gl-disclosure-dropdown-item>
      </ul>
    </div>
    <div v-if="hiddenPreferences.length" data-testid="hidden-preferences" class="gl-mt-4">
      <span class="gl-pl-4 gl-text-sm gl-font-bold">{{ $options.i18n.hidden }}</span>
      <ul class="gl-m-0 gl-mt-2 gl-list-none gl-p-0">
        <gl-disclosure-dropdown-item
          v-for="metadata in hiddenPreferences"
          :key="metadata.key"
          class="work-item-dropdown-toggle"
          @action="toggleMetadataDisplaySettings(metadata.key)"
        >
          <template #list-item>
            <div class="gl-flex gl-items-center gl-gap-3">
              <gl-icon :name="metadata.icon" />
              <gl-toggle
                :value="false"
                :label="metadata.label"
                class="gl-w-full gl-justify-between"
                label-position="left"
              />
            </div>
          </template>
        </gl-disclosure-dropdown-item>
      </ul>
    </div>
  </div>
</template>
