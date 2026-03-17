<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlIcon,
  GlDisclosureDropdownGroup,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__, sprintf } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { ROUTES } from '~/work_items/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import WorkItemsNewSavedViewModal from './work_items_new_saved_view_modal.vue';

export default {
  name: 'WorkItemsSavedViewSelector',
  components: {
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    GlButton,
    WorkItemsNewSavedViewModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['isGroup'],
  props: {
    savedView: {
      type: Object,
      required: true,
    },
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
  },
  emits: ['unsubscribe-saved-view', 'delete-saved-view'],
  data() {
    return {
      isNewViewModalVisible: false,
      dropdownTooltip: this.savedView.name,
    };
  },
  computed: {
    isViewActive() {
      const id = getIdFromGraphQLId(this.savedView.id).toString();
      return this.$route.params.view_id === id;
    },
    viewLink() {
      const id = getIdFromGraphQLId(this.savedView.id).toString();
      return { name: ROUTES.savedView, params: { view_id: id }, query: undefined };
    },
    canUpdateSavedView() {
      return this.savedView?.userPermissions?.updateSavedView;
    },
    canDeleteSavedView() {
      return this.savedView?.userPermissions?.deleteSavedView;
    },
  },
  methods: {
    editView() {
      this.isNewViewModalVisible = true;
    },
    async copyViewLink() {
      try {
        await copyToClipboard(window.location.href);
        this.$toast.show(s__('WorkItem|Link to view copied to clipboard.'));
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    unsubscribeView() {
      this.$emit('unsubscribe-saved-view', this.savedView);
    },
    async deleteView() {
      const title = s__('WorkItem|Are you sure you want to delete this view?');
      const namespaceType = this.isGroup ? __('group') : __('project');
      const message = sprintf(
        s__(
          'WorkItem|Deleting a view removes it from this %{type} and from anyone who had access to it. This action cannot be undone.',
        ),
        { type: namespaceType },
      );

      const confirmed = await confirmAction(null, {
        title,
        modalHtmlMessage: `<span>${message}</span>`,
        primaryBtnVariant: 'danger',
        primaryBtnText: s__('WorkItem|Delete view'),
      });

      if (confirmed) {
        this.$emit('delete-saved-view', this.savedView);
      }
    },
  },
};
</script>

<template>
  <div data-testid="selector-wrapper">
    <gl-disclosure-dropdown
      v-if="isViewActive"
      v-gl-tooltip.top.viewport="dropdownTooltip"
      category="tertiary"
      :toggle-text="savedView.name"
      auto-close
      class="saved-view-selector saved-view-selector-active !gl-h-full !gl-rounded-none"
      toggle-class="gl-max-w-15 md:gl-max-w-none gl-truncate"
      data-testid="saved-view-selector"
      @shown="dropdownTooltip = ''"
      @hidden="dropdownTooltip = savedView.name"
    >
      <gl-disclosure-dropdown-item
        v-if="canUpdateSavedView"
        data-testid="edit-action"
        @action="editView"
      >
        <template #list-item>
          <gl-icon name="pencil" class="gl-mr-2" variant="subtle" />
          {{ s__('WorkItem|Edit') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item data-testid="copy-action" @action="copyViewLink">
        <template #list-item>
          <gl-icon name="link" class="gl-mr-2" variant="subtle" />
          {{ s__('WorkItem|Copy link to view') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item data-testid="unsubscribe-action" @action="unsubscribeView">
        <template #list-item>
          <gl-icon name="close" class="gl-mr-2" variant="subtle" />
          {{ s__('WorkItem|Remove from list') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-group v-if="canDeleteSavedView" bordered>
        <gl-disclosure-dropdown-item
          data-testid="delete-action"
          variant="danger"
          @action="deleteView"
        >
          <template #list-item>
            <gl-icon name="remove" class="gl-mr-2" variant="current" />
            {{ s__('WorkItem|Delete view') }}
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>
    <gl-button
      v-else
      v-gl-tooltip.top.viewport="savedView.name"
      category="tertiary"
      :to="viewLink"
      class="saved-view-selector gl-h-full gl-max-w-15 gl-truncate !gl-rounded-none md:gl-max-w-none"
    >
      {{ savedView.name }}
    </gl-button>
    <work-items-new-saved-view-modal
      v-model="isNewViewModalVisible"
      :saved-view="savedView"
      :full-path="fullPath"
      :sort-key="sortKey"
      :filters="filters"
      :display-settings="displaySettings"
      @hide="isNewViewModalVisible = false"
    />
  </div>
</template>
