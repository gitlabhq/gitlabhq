<script>
import { GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import produce from 'immer';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { InternalEvents } from '~/tracking';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import updateWorkItemsDisplaySettings from '~/work_items/graphql/update_user_preferences.mutation.graphql';
import getUserWorkItemsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import { ROUTES } from '~/work_items/constants';

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
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    isSavedView() {
      return this.$route?.name === ROUTES.savedView;
    },
    shouldOpenItemsInSidePanel() {
      return this.commonPreferences?.shouldOpenItemsInSidePanel ?? true;
    },
  },
  methods: {
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
                variables: {
                  namespace: this.fullPath,
                  workItemTypeId: this.workItemTypeId,
                  userPreferencesOnly: this.isSavedView,
                },
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
