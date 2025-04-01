<script>
import { GlCollapsibleListbox, GlToggle } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import setIsShowingLabelsMutation from '~/graphql_shared/client/set_is_showing_labels.mutation.graphql';
import currentUserPreferencesQuery from '../queries/current_user_preferences.query.graphql';
import updatePreferencesMutation from '../queries/update_preferences.mutation.graphql';

export default {
  apollo: {
    isShowingLabels: {
      query: isShowingLabelsQuery,
      update: (data) => data.isShowingLabels,
    },
    preferences: {
      query: currentUserPreferencesQuery,
      update: (data) => data.currentUser.userPreferences,
      skip() {
        return !this.listTypeToggleEnabled;
      },
    },
  },
  components: {
    GlCollapsibleListbox,
    GlToggle,
    LocalStorageSync,
  },
  mixins: [InternalEvents.mixin()],
  inject: { listTypeToggleEnabled: { default: false } },
  data() {
    return {
      isShowingLabels: null,
      savingPreferences: false,
      preferences: {},
    };
  },
  computed: {
    listTypeItems() {
      if (!this.listTypeToggleEnabled) return [];

      return [
        {
          text: __('Group by'),
          options: [
            {
              text: __('Workflow'),
              subText: __('Next step in review workflow'),
              value: 'action_based',
            },
            {
              text: __('Role'),
              subText: __('My reviews and assigned'),
              value: 'role_based',
            },
          ],
        },
      ];
    },
  },
  methods: {
    async toggleShowLabels() {
      const isShowingLabels = !this.isShowingLabels;

      try {
        await this.setShowLabels(isShowingLabels);

        this.trackEvent('click_toggle_labels_on_merge_request_dashboard', {
          label: 'show_labels',
          property: isShowingLabels ? 'on' : 'off',
        });
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    setShowLabels(isShowingLabels) {
      return this.$apollo.mutate({
        mutation: setIsShowingLabelsMutation,
        variables: {
          isShowingLabels,
        },
      });
    },
    async updateListType(mergeRequestDashboardListType) {
      this.savingPreferences = true;

      try {
        await this.$apollo.mutate({
          mutation: updatePreferencesMutation,
          variables: {
            mergeRequestDashboardListType: mergeRequestDashboardListType.toUpperCase(),
          },
        });

        window.navigation.reload();
      } catch (error) {
        this.savingPreferences = false;

        createAlert({
          message: __('There was an error updating your display preferences.'),
          error,
          captureError: true,
          primaryButton: {
            text: __('Try again'),
            clickHandler: () => {
              this.updateListType(mergeRequestDashboardListType);
            },
          },
        });
      }
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :selected="preferences.listType"
    :items="listTypeItems"
    icon="preferences"
    no-caret
    text-sr-only
    :header-text="listTypeToggleEnabled ? __('Display preferences') : null"
    :toggle-text="__('Display preferences')"
    placement="bottom-end"
    :loading="savingPreferences"
    :toggle-class="{ '!gl-px-3': savingPreferences }"
    @select="updateListType"
  >
    <template #list-item="{ item }">
      <div class="gl-font-bold">{{ item.text }}</div>
      <div class="gl-text-gray-600">{{ item.subText }}</div>
    </template>
    <template #footer>
      <div
        class="gl-flex gl-flex-col gl-px-4 gl-py-3"
        :class="{
          'gl-border-t-1 gl-border-t-dropdown-divider gl-border-t-solid': listTypeToggleEnabled,
          'toggle-labels-footer': !listTypeToggleEnabled,
        }"
      >
        <local-storage-sync
          :value="isShowingLabels"
          storage-key="gl-show-merge-request-labels"
          @input="setShowLabels"
        />
        <gl-toggle
          :label="__('Show labels')"
          label-position="left"
          :value="isShowingLabels"
          @change="toggleShowLabels"
        />
      </div>
    </template>
  </gl-collapsible-listbox>
</template>

<style>
div:has(+ .toggle-labels-footer) {
  display: none;
}
</style>
