<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlIcon, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import WorkItemsNewSavedViewModal from './work_items_new_saved_view_modal.vue';
import WorkItemsExistingSavedViewsModal from './work_items_existing_saved_views_modal.vue';

export default {
  name: 'WorkItemsCreateSavedViewDropdown',
  components: {
    GlIcon,
    GlLink,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    WorkItemsNewSavedViewModal,
    WorkItemsExistingSavedViewsModal,
  },
  i18n: {
    addViewButtonText: s__('WorkItem|Add view'),
    newViewTitle: s__('WorkItem|New view'),
    existingViewDropdownTitle: s__('WorkItem|Browse views'),
    subscriptionLimitWarningMessage: s__(
      'WorkItem|You have reached the maximum number of views in your list.',
    ),
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    sortKey: {
      type: String,
      required: true,
    },
    filters: {
      type: Object,
      required: false,
      default: () => {},
    },
    displaySettings: {
      type: Object,
      required: false,
      default: () => {},
    },
    showSubscriptionLimitWarning: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isNewViewModalVisible: false,
      isExistingViewModalVisible: false,
    };
  },
};
</script>

<template>
  <div class="gl-self-center">
    <gl-disclosure-dropdown
      icon="plus"
      category="tertiary"
      :toggle-text="$options.i18n.addViewButtonText"
      no-caret
      left
      data-testid="add-saved-view-toggle"
    >
      <gl-disclosure-dropdown-item @action="isNewViewModalVisible = true">
        <template #list-item>
          <span>{{ $options.i18n.newViewTitle }}</span>
        </template>
      </gl-disclosure-dropdown-item>
      <gl-disclosure-dropdown-item @action="isExistingViewModalVisible = true">
        <template #list-item>
          <span>{{ $options.i18n.existingViewDropdownTitle }}</span>
        </template>
      </gl-disclosure-dropdown-item>
      <div
        v-if="showSubscriptionLimitWarning"
        class="gl-mx-2 gl-flex gl-gap-3 gl-rounded-base gl-bg-orange-50 gl-p-3"
      >
        <gl-icon name="warning" :size="16" class="gl-mt-1 gl-shrink-0 gl-text-orange-500" />
        <span class="gl-text-sm">
          {{ $options.i18n.subscriptionLimitWarningMessage }}
          <!-- TODO: Replace with actual learn more URL -->
          <gl-link href="#" target="_blank">
            {{ s__('WorkItem|Learn more.') }}
          </gl-link>
        </span>
      </div>
    </gl-disclosure-dropdown>
    <work-items-new-saved-view-modal
      v-model="isNewViewModalVisible"
      :full-path="fullPath"
      :sort-key="sortKey"
      :filters="filters"
      :display-settings="displaySettings"
      :show-subscription-limit-warning="showSubscriptionLimitWarning"
      @hide="isNewViewModalVisible = false"
    />
    <work-items-existing-saved-views-modal
      v-model="isExistingViewModalVisible"
      :full-path="fullPath"
      :show-subscription-limit-warning="showSubscriptionLimitWarning"
      @show-new-view-modal="isNewViewModalVisible = true"
    />
  </div>
</template>
