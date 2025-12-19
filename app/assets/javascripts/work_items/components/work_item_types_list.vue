<script>
import { GlDisclosureDropdown, GlButton, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import { s__, __ } from '~/locale';

export default {
  name: 'WorkItemTypesList',
  components: {
    CrudComponent,
    GlDisclosureDropdown,
    GlButton,
    WorkItemTypeIcon,
    GlLoadingIcon,
    GlAlert,
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
    dropdownItems() {
      return [
        {
          text: s__('WorkItem|Edit name and icon'),
          action: () => {},
          extraAttrs: {
            'data-testid': 'work-item-type-edit-name',
          },
        },
        {
          text: __('Delete'),
          action: () => {},
          variant: 'danger',
          extraAttrs: {
            'data-testid': 'work-item-type-delete',
          },
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-5" @dismiss="errorMessage = ''">
      {{ errorMessage }}
    </gl-alert>
    <crud-component :title="s__('WorkItem|Types')" :count="count">
      <template #actions>
        <gl-button size="small">
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
          <!-- Type Column -->
          <work-item-type-icon
            :work-item-type="item.name"
            class="gl-font-semibold gl-text-default"
            icon-class="gl-flex-shrink-0 gl-mr-2"
            show-text
            icon-variant="subtle"
          />
          <!-- Options Column -->

          <gl-disclosure-dropdown
            :items="dropdownItems"
            :toggle-id="`work-item-type-actions-${item.id}`"
            icon="ellipsis_v"
            no-caret
            text-sr-only
            :toggle-text="__('Actions')"
            category="tertiary"
          />
        </div>
      </div>
    </crud-component>
  </div>
</template>
