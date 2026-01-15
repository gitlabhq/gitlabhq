<script>
import {
  GlDisclosureDropdown,
  GlButton,
  GlLoadingIcon,
  GlAlert,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import CreateEditWorkItemTypeForm from '~/work_items/components/create_edit_work_item_type_form.vue';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import { s__ } from '~/locale';

export default {
  name: 'WorkItemTypesList',
  components: {
    CrudComponent,
    GlDisclosureDropdown,
    GlButton,
    WorkItemTypeIcon,
    GlLoadingIcon,
    GlAlert,
    CreateEditWorkItemTypeForm,
    GlDisclosureDropdownItem,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      workItemTypes: [],
      errorMessage: '',
      createEditWorkItemTypeFormVisible: false,
      selectedWorkItemType: null,
    };
  },
  apollo: {
    workItemTypes: {
      query: namespaceWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.namespace?.workItemTypes?.nodes || [];
      },
      error(error) {
        this.errorMessage = s__('WorkItem|Failed to fetch work item types.');
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    count() {
      return this.workItemTypes?.length;
    },
    isLoading() {
      return this.$apollo.queries.workItemTypes.loading;
    },
  },
  methods: {
    editWorkItemType(workItemType) {
      this.selectedWorkItemType = workItemType;
      this.createEditWorkItemTypeFormVisible = true;
    },
    closeModal() {
      this.createEditWorkItemTypeFormVisible = false;
      this.selectedWorkItemType = null;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-5" @dismiss="errorMessage = ''">
      {{ errorMessage }}
    </gl-alert>
    <create-edit-work-item-type-form
      :is-visible="createEditWorkItemTypeFormVisible"
      :work-item-type="selectedWorkItemType"
      :is-edit-mode="!!selectedWorkItemType"
      @close="closeModal"
    />
    <crud-component :title="s__('WorkItem|Types')" :count="count">
      <template #actions>
        <gl-button size="small" @click="createEditWorkItemTypeFormVisible = true">
          {{ s__('WorkItem|New type') }}
        </gl-button>
      </template>

      <gl-loading-icon v-if="isLoading" size="lg" />
      <div v-else class="-gl-my-4" data-testid="work-item-types-table">
        <!-- Table Rows -->
        <div
          v-for="item in workItemTypes"
          :key="item.id"
          class="gl-border-b gl-flex gl-justify-between gl-gap-4 gl-border-b-subtle gl-py-4 last:gl-border-b-0"
          :data-testid="`work-item-type-row-${item.id}`"
        >
          <work-item-type-icon
            :work-item-type="item.name"
            class="gl-font-semibold gl-text-default"
            icon-class="gl-flex-shrink-0 gl-mr-2"
            show-text
            icon-variant="subtle"
          />

          <gl-disclosure-dropdown
            :toggle-id="`work-item-type-actions-${item.id}`"
            icon="ellipsis_v"
            no-caret
            text-sr-only
            :toggle-text="__('Actions')"
            category="tertiary"
          >
            <gl-disclosure-dropdown-item @action="editWorkItemType(item)">
              <template #list-item>
                {{ s__('WorkItem|Edit name and icon') }}
              </template>
            </gl-disclosure-dropdown-item>
            <gl-disclosure-dropdown-item variant="danger">
              <template #list-item>
                {{ __('Delete') }}
              </template>
            </gl-disclosure-dropdown-item>
          </gl-disclosure-dropdown>
        </div>
      </div>
    </crud-component>
  </div>
</template>
