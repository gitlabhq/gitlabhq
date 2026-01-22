<script>
import {
  GlDisclosureDropdown,
  GlButton,
  GlLoadingIcon,
  GlAlert,
  GlDisclosureDropdownItem,
  GlBadge,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import CreateEditWorkItemTypeForm from '~/work_items/components/create_edit_work_item_type_form.vue';
import organisationWorkItemTypesQuery from '~/work_items/graphql/organisation_work_item_types.query.graphql';
import workItemTypesConfigurationQuery from '~/work_items/graphql/work_item_types_configuration.query.graphql';
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
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    fullPath: {
      type: String,
      required: false,
      default: '',
    },
    config: {
      type: Object,
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
      query() {
        return this.fullPath ? workItemTypesConfigurationQuery : organisationWorkItemTypesQuery;
      },
      variables() {
        if (!this.fullPath) {
          return {};
        }
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return this.fullPath
          ? data.namespace?.workItemTypes?.nodes
          : data.organisation?.workItemTypes?.nodes;
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
    canCreate() {
      return this.config?.workItemTypeSettingsPermissions?.includes('create');
    },
    canEdit() {
      return this.config?.workItemTypeSettingsPermissions?.includes('edit');
    },
    canArchive() {
      return this.config?.workItemTypeSettingsPermissions?.includes('archive');
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
    getTooltipText(item) {
      const baseMessage = s__(
        'WorkItem|This is a system type that cannot be renamed, disabled, or deleted.',
      );

      let additionalText = '';

      if (item.isServiceDesk) {
        additionalText = s__('WorkItem|Usage is controlled by the Service Desk feature.');
      } else if (item.isGroupWorkItemType) {
        additionalText = s__('WorkItem|Usage is limited to groups.');
      }

      return additionalText ? `${baseMessage} ${additionalText}` : baseMessage;
    },
    isLocked(item) {
      // we cant use !item.isConfigurable because it can also be undefined/null in which case we dont want
      // to show locked icon
      return item.isConfigurable === false;
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
    <!--
      There is a separate view for subgroup/project levels where the user cannot create/edit/archive but showing only the
      enabled and disabled types as two separate tables which will be utilising the same query response , we will require that setting here. Either we read it
      from context/ or we just add another permission or the work item settings
    -->
    <crud-component :title="s__('WorkItem|Types')" :count="count">
      <template #actions>
        <gl-button v-if="canCreate" size="small" @click="createEditWorkItemTypeFormVisible = true">
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
          <div class="gl-flex gl-items-center gl-gap-2">
            <work-item-type-icon
              :work-item-type="item.name"
              class="gl-font-semibold gl-text-default"
              icon-class="gl-flex-shrink-0 gl-mr-2"
              show-text
              icon-variant="subtle"
            />
            <gl-badge
              v-if="isLocked(item)"
              v-gl-tooltip
              icon="lock"
              :data-testid="`locked-icon-${item.id}`"
              :title="getTooltipText(item)"
              :aria-label="getTooltipText(item)"
              class="gl-shrink-0"
            />
          </div>

          <!-- Options Column -->

          <gl-disclosure-dropdown
            :toggle-id="`work-item-type-actions-${item.id}`"
            icon="ellipsis_v"
            no-caret
            text-sr-only
            :toggle-text="__('Actions')"
            category="tertiary"
          >
            <gl-disclosure-dropdown-item v-if="canEdit" @action="editWorkItemType(item)">
              <template #list-item>
                {{ s__('WorkItem|Edit name and icon') }}
              </template>
            </gl-disclosure-dropdown-item>
            <gl-disclosure-dropdown-item v-if="canArchive" variant="danger">
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
