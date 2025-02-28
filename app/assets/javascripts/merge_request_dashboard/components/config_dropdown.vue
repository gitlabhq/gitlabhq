<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlToggle } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { InternalEvents } from '~/tracking';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import setIsShowingLabelsMutation from '~/graphql_shared/client/set_is_showing_labels.mutation.graphql';

export default {
  apollo: {
    isShowingLabels: {
      query: isShowingLabelsQuery,
      update: (data) => data.isShowingLabels,
    },
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlToggle,
    LocalStorageSync,
  },
  mixins: [InternalEvents.mixin()],
  data() {
    return {
      isShowingLabels: null,
    };
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
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    icon="preferences"
    no-caret
    text-sr-only
    :toggle-text="__('Preferences')"
    placement="bottom-end"
  >
    <gl-disclosure-dropdown-item @action="toggleShowLabels">
      <local-storage-sync
        :value="isShowingLabels"
        storage-key="gl-show-merge-request-labels"
        @input="setShowLabels"
      />
      <div class="gl-new-dropdown-item-content">
        <div class="gl-new-dropdown-item-text-wrapper">
          <gl-toggle :label="__('Show labels')" label-position="left" :value="isShowingLabels" />
        </div>
      </div>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
