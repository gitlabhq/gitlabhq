<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlIcon,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { ROUTES } from '../constants';

export default {
  name: 'WorkItemsSavedViewSelector',
  components: {
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
  },
  props: {
    savedView: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isViewActive() {
      return this.$route.params.view_id === this.savedView.id;
    },
  },
  methods: {
    onViewClick() {
      if (!this.isViewActive) {
        this.$router
          .push({ name: ROUTES.savedView, params: { view_id: this.savedView.id } })
          .catch((error) => {
            if (error.name !== 'NavigationDuplicated') {
              throw error;
            }
          });
      }
    },
    editView() {
      // TODO: to replace this with logic to edit a view
      return '';
    },
    duplicateView() {
      // TODO: replace this with logic to duplicate a view
      return '';
    },
    copyViewLink() {
      // TODO: to replace this with copying logic, saved view link will look like so:
      // http://127.0.0.1:3000/flightjs/Flight/-/work_items/saved_view/:id
      return '';
    },
    removeView() {
      // TODO: to replace with logic to unsubsribe from a view. The view is not deleted.
      return '';
    },
    deleteView() {
      // TODO: to replace with logic to delete view.
      return '';
    },
  },
};
</script>

<template>
  <!-- TODO: Make this a <router-link> when !isViewActive, and <gl-disclosure-dropdown> when isViewActive -->
  <div data-testid="selector-wrapper" class="gl-cursor-pointer" @click="onViewClick">
    <gl-disclosure-dropdown
      category="tertiary"
      :toggle-text="savedView.name"
      auto-close
      :no-caret="!isViewActive"
      class="saved-view-selector gl-pointer-events-none !gl-h-full !gl-rounded-none"
      :class="{ 'saved-view-selector-active gl-pointer-events-auto': isViewActive }"
      data-testid="saved-view-selector"
    >
      <gl-disclosure-dropdown-item data-testid="edit-action" @action="editView">
        <template #list-item>
          <gl-icon name="pencil" class="gl-mr-2" variant="subtle" />
          {{ s__('WorkItem|Edit') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item data-testid="duplicate-action" @action="duplicateView">
        <template #list-item>
          <gl-icon name="copy-to-clipboard" class="gl-mr-2" variant="subtle" />
          {{ s__('WorkItem|Duplicate') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item data-testid="copy-action" @action="copyViewLink">
        <template #list-item>
          <gl-icon name="link" class="gl-mr-2" variant="subtle" />
          {{ s__('WorkItem|Copy link to view') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-item data-testid="unsubscribe-action" @action="removeView">
        <template #list-item>
          <gl-icon name="close" class="gl-mr-2" variant="subtle" />
          {{ s__('WorkItem|Remove from list') }}
        </template>
      </gl-disclosure-dropdown-item>

      <gl-disclosure-dropdown-group bordered>
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
  </div>
</template>
