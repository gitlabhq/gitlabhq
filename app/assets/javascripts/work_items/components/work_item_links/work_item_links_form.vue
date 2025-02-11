<script>
import { GlFormGroup, GlForm, GlButton, GlFormInput, GlFormCheckbox, GlTooltip } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { fetchPolicies } from '~/lib/graphql';
import WorkItemTokenInput from '../shared/work_item_token_input.vue';
import { addHierarchyChild, addHierarchyChildren } from '../../graphql/cache_utils';
import namespaceWorkItemTypesQuery from '../../graphql/namespace_work_item_types.query.graphql';
import updateWorkItemHierarchyMutation from '../../graphql/update_work_item_hierarchy.mutation.graphql';
import createWorkItemMutation from '../../graphql/create_work_item.mutation.graphql';
import {
  FORM_TYPES,
  WORK_ITEMS_TYPE_MAP,
  WORK_ITEM_TYPE_ENUM_TASK,
  I18N_WORK_ITEM_CREATE_BUTTON_LABEL,
  I18N_WORK_ITEM_ADD_BUTTON_LABEL,
  I18N_WORK_ITEM_ADD_MULTIPLE_BUTTON_LABEL,
  I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL,
  I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_TOOLTIP,
  WORK_ITEM_TYPE_VALUE_EPIC,
  I18N_MAX_WORK_ITEMS_ERROR_MESSAGE,
  MAX_WORK_ITEMS,
  sprintfWorkItem,
  WIDGET_TYPE_MILESTONE,
  WIDGET_TYPE_ITERATION,
} from '../../constants';
import WorkItemProjectsListbox from './work_item_projects_listbox.vue';
import WorkItemGroupsListbox from './work_item_groups_listbox.vue';

export default {
  components: {
    GlForm,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    GlTooltip,
    WorkItemTokenInput,
    WorkItemProjectsListbox,
    WorkItemGroupsListbox,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['hasIterationsFeature'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableGid: {
      type: String,
      required: false,
      default: null,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    childrenIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    parentConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentIteration: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    parentMilestone: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    formType: {
      type: String,
      required: true,
    },
    parentWorkItemType: {
      type: String,
      required: false,
      default: '',
    },
    childrenType: {
      type: String,
      required: false,
      default: WORK_ITEM_TYPE_ENUM_TASK,
    },
    fullName: {
      type: String,
      required: false,
      default: '',
    },
  },
  apollo: {
    workItemTypes: {
      query() {
        return namespaceWorkItemTypesQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
    },
  },
  data() {
    return {
      workItemTypes: [],
      workItemsToAdd: [],
      error: null,
      isInputValid: true,
      search: '',
      selectedProjectFullPath: this.isGroup ? null : this.fullPath,
      selectedGroupFullPath: null,
      childToCreateTitle: null,
      confidential: this.parentConfidential,
      submitInProgress: false,
    };
  },
  computed: {
    workItemChildIsEpic() {
      return this.childrenTypeValue === WORK_ITEM_TYPE_VALUE_EPIC;
    },
    workItemInput() {
      let workItemInput = {
        title: this.search?.title || this.search,
        workItemTypeId: this.childWorkItemType,
        hierarchyWidget: {
          parentId: this.issuableGid,
        },
        confidential: this.parentConfidential || this.confidential,
      };

      if (this.selectedProjectFullPath && !this.workItemChildIsEpic) {
        workItemInput = {
          ...workItemInput,
          namespacePath: this.selectedProjectFullPath,
        };
      } else if (this.selectedGroupFullPath && this.workItemChildIsEpic) {
        workItemInput = {
          ...workItemInput,
          namespacePath: this.selectedGroupFullPath,
        };
      } else {
        workItemInput = {
          ...workItemInput,
          projectPath: this.fullPath,
        };
      }

      if (this.parentMilestoneId && this.isWidgetSupported(WIDGET_TYPE_MILESTONE)) {
        workItemInput = {
          ...workItemInput,
          milestoneWidget: {
            milestoneId: this.parentMilestoneId,
          },
        };
      }

      if (this.associateIteration && this.isWidgetSupported(WIDGET_TYPE_ITERATION)) {
        workItemInput = {
          ...workItemInput,
          iterationWidget: {
            iterationId: this.parentIterationId,
          },
        };
      }

      return workItemInput;
    },
    isCreateForm() {
      return this.formType === FORM_TYPES.create;
    },
    childrenTypeName() {
      return WORK_ITEMS_TYPE_MAP[this.childrenType]?.name;
    },
    childrenTypeValue() {
      return WORK_ITEMS_TYPE_MAP[this.childrenType]?.value;
    },
    addOrCreateButtonLabel() {
      if (this.isCreateForm) {
        return sprintfWorkItem(I18N_WORK_ITEM_CREATE_BUTTON_LABEL, this.childrenTypeName);
      }
      if (this.workItemsToAdd.length > 1) {
        return sprintfWorkItem(I18N_WORK_ITEM_ADD_MULTIPLE_BUTTON_LABEL, this.childrenTypeName);
      }
      return sprintfWorkItem(I18N_WORK_ITEM_ADD_BUTTON_LABEL, this.childrenTypeName);
    },
    confidentialityCheckboxLabel() {
      return sprintfWorkItem(I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_LABEL, this.childrenTypeName);
    },
    confidentialityCheckboxTooltip() {
      return sprintfWorkItem(
        I18N_WORK_ITEM_CONFIDENTIALITY_CHECKBOX_TOOLTIP,
        this.childrenTypeName,
        this.parentWorkItemType,
      );
    },
    showConfidentialityTooltip() {
      return this.isCreateForm && this.parentConfidential;
    },
    addOrCreateMethod() {
      return this.isCreateForm ? this.createChild : this.addChild;
    },
    childWorkItemType() {
      return this.workItemTypes.find((type) => type.name === this.childrenTypeValue)?.id;
    },
    parentIterationId() {
      return this.parentIteration?.id;
    },
    associateIteration() {
      return this.parentIterationId && this.hasIterationsFeature;
    },
    parentMilestoneId() {
      return this.parentMilestone?.id;
    },
    canCreateGroupLevelWorkItems() {
      return this.glFeatures.createGroupLevelWorkItems;
    },
    hasSuppliedNewItemName() {
      return this.search.length > 0;
    },
    hasSelectedProject() {
      return Boolean(this.selectedProjectFullPath);
    },
    canSubmitForm() {
      if (this.isCreateForm) {
        if (this.isGroup) {
          if (this.workItemChildIsEpic) {
            // must supply name, project will be ignored in request
            return this.hasSuppliedNewItemName;
          }
          if (!this.canCreateGroupLevelWorkItems) {
            // must supply name and project
            return this.hasSuppliedNewItemName && this.hasSelectedProject;
          }
        }
        return this.hasSuppliedNewItemName;
      }
      return this.workItemsToAdd.length > 0 && this.areWorkItemsToAddValid;
    },
    invalidWorkItemsToAdd() {
      return this.parentConfidential
        ? this.workItemsToAdd.filter((workItem) => !workItem.confidential)
        : [];
    },
    areWorkItemsToAddValid() {
      return this.invalidWorkItemsToAdd.length === 0 && this.areWorkItemsToAddWithinLimit;
    },
    showWorkItemsToAddInvalidMessage() {
      return !this.isCreateForm && this.invalidWorkItemsToAdd.length > 0;
    },
    workItemsToAddInvalidMessage() {
      return sprintf(
        s__(
          'WorkItem|%{invalidWorkItemsList} cannot be added: Cannot assign a non-confidential %{childWorkItemType} to a confidential parent %{parentWorkItemType}. Make the selected %{childWorkItemType} confidential and try again.',
        ),
        {
          invalidWorkItemsList: this.invalidWorkItemsToAdd.map(({ title }) => title).join(', '),
          childWorkItemType: this.childrenTypeName,
          parentWorkItemType: this.parentWorkItemType,
        },
      );
    },
    areWorkItemsToAddWithinLimit() {
      return this.workItemsToAdd.length <= MAX_WORK_ITEMS;
    },
  },
  watch: {
    workItemsToAdd() {
      this.unsetError();
    },
    workItemChildIsEpic: {
      handler(isEpic) {
        this.selectedGroupFullPath = isEpic ? this.fullPath : null;
      },
      immediate: true,
    },
  },
  methods: {
    getConfidentialityTooltipTarget() {
      // We want tooltip to be anchored to `input` within checkbox component
      // but `$el.querySelector('input')` doesn't work. 🤷‍♂️
      return this.$refs.confidentialityCheckbox?.$el;
    },
    unsetError() {
      this.error = null;
      this.isInputValid = true;
    },
    markFormSubmitInProgress(value) {
      this.submitInProgress = value;
      this.$emit('update-in-progress', this.submitInProgress);
      if (!value) this.$refs.wiTitleInput?.$el?.focus();
    },
    addChild() {
      this.markFormSubmitInProgress(true);
      this.$apollo
        .mutate({
          mutation: updateWorkItemHierarchyMutation,
          fetchPolicy: fetchPolicies.NO_CACHE,
          variables: {
            input: {
              id: this.issuableGid,
              hierarchyWidget: {
                childrenIds: this.workItemsToAdd.map((wi) => wi.id),
              },
            },
          },
          update: (
            cache,
            {
              data: {
                workItemUpdate: { workItem },
              },
            },
          ) =>
            addHierarchyChildren({
              cache,
              id: this.issuableGid,
              workItem,
              childrenIds: this.workItemsToAdd.map((wi) => wi.id),
            }),
        })
        .then(({ data }) => {
          // Marking submitInProgress cannot be in finally block
          // as the form may get close before the event is emitted
          this.markFormSubmitInProgress(false);
          if (data.workItemUpdate?.errors?.length) {
            [this.error] = data.workItemUpdate.errors;
          } else {
            this.unsetError();
            this.workItemsToAdd = [];
          }
        })
        .catch(() => {
          this.error = this.$options.i18n.addChildErrorMessage;
          this.isInputValid = false;
          this.markFormSubmitInProgress(false);
        })
        .finally(() => {
          this.search = '';
        });
    },
    createChild() {
      if (!this.canSubmitForm) {
        return;
      }
      this.markFormSubmitInProgress(true);
      this.$apollo
        .mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: this.workItemInput,
          },
          update: (cache, { data }) =>
            addHierarchyChild({
              cache,
              id: this.issuableGid,
              workItem: data.workItemCreate.workItem,
            }),
        })
        .then(({ data }) => {
          // Marking submitInProgress cannot be in finally block
          // as the form may get close before the event is emitted
          this.markFormSubmitInProgress(false);
          if (data.workItemCreate?.errors?.length) {
            [this.error] = data.workItemCreate.errors;
          } else {
            this.unsetError();
            this.$emit('addChild');
          }
        })
        .catch(() => {
          this.error = this.$options.i18n.createChildErrorMessage;
          this.isInputValid = false;
          this.markFormSubmitInProgress(false);
        })
        .finally(() => {
          this.search = '';
          this.childToCreateTitle = null;
        });
    },
    closeForm() {
      this.$emit('cancel');
    },
    isWidgetSupported(widgetType) {
      const childrenType = this.workItemTypes.find((type) => type.name === this.childrenTypeName);
      const widgetDefinitions = childrenType?.widgetDefinitions?.flatMap((i) => i.type) || [];
      return widgetDefinitions.indexOf(widgetType) !== -1;
    },
  },
  i18n: {
    titleInputLabel: __('Title'),
    projectInputLabel: __('Project'),
    groupInputLabel: __('Group'),
    addChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to add a child. Please try again.',
    ),
    createChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to create a child. Please try again.',
    ),
    titleInputPlaceholder: s__('WorkItem|Add a title'),
    projectInputPlaceholder: s__('WorkItem|Select a project'),
    groupInputPlaceholder: s__('WorkItem|Select a group'),
    titleInputValidationMessage: __('Maximum of 255 characters'),
    maxItemsErrorMessage: I18N_MAX_WORK_ITEMS_ERROR_MESSAGE,
  },
};
</script>

<template>
  <gl-form data-testid="add-item-form" @submit.prevent="addOrCreateMethod">
    <template v-if="isCreateForm">
      <div class="gl-flex gl-gap-x-3">
        <gl-form-group
          class="gl-w-full"
          :label="$options.i18n.titleInputLabel"
          :description="$options.i18n.titleInputValidationMessage"
          :invalid-feedback="error"
          :state="isInputValid"
          data-testid="work-items-create-form-group"
        >
          <gl-form-input
            ref="wiTitleInput"
            v-model="search"
            :placeholder="$options.i18n.titleInputPlaceholder"
            :state="isInputValid"
            maxlength="255"
            class="gl-mb-3"
            autofocus
          />
        </gl-form-group>
        <gl-form-group
          v-if="!workItemChildIsEpic"
          class="gl-w-full"
          :label="$options.i18n.projectInputLabel"
          :description="$options.i18n.projectValidationMessage"
        >
          <work-item-projects-listbox
            v-model="selectedProjectFullPath"
            class="gl-w-full"
            :full-path="fullPath"
            :current-project-name="fullName"
            :is-group="isGroup"
          />
        </gl-form-group>
        <gl-form-group
          v-else
          class="gl-w-full"
          :label="$options.i18n.groupInputLabel"
          :description="$options.i18n.groupValidationMessage"
        >
          <work-item-groups-listbox
            v-model="selectedGroupFullPath"
            class="gl-w-full"
            :full-path="fullPath"
            :current-group-name="fullName"
            :is-group="isGroup"
            @error="$emit('error', $event)"
          />
        </gl-form-group>
      </div>
      <gl-form-checkbox
        ref="confidentialityCheckbox"
        v-model="confidential"
        name="isConfidential"
        class="gl-mb-5 md:!gl-mb-3"
        :disabled="parentConfidential"
        >{{ confidentialityCheckboxLabel }}</gl-form-checkbox
      >
      <gl-tooltip
        v-if="showConfidentialityTooltip"
        :target="getConfidentialityTooltipTarget"
        triggers="hover"
        >{{ confidentialityCheckboxTooltip }}</gl-tooltip
      >
    </template>
    <div v-else class="gl-mb-4">
      <work-item-token-input
        v-model="workItemsToAdd"
        :is-create-form="isCreateForm"
        :is-group="isGroup"
        :parent-work-item-id="issuableGid"
        :children-type="childrenType"
        :children-ids="childrenIds"
        :are-work-items-to-add-valid="areWorkItemsToAddValid"
        :full-path="fullPath"
      />
      <div
        v-if="showWorkItemsToAddInvalidMessage"
        class="gl-text-danger"
        data-testid="work-items-invalid"
      >
        {{ workItemsToAddInvalidMessage }}
      </div>
      <div v-if="error" class="gl-mt-3 gl-text-danger" data-testid="work-items-error">
        {{ error }}
      </div>
      <div
        v-if="!areWorkItemsToAddWithinLimit"
        class="gl-mb-2 gl-text-red-500"
        data-testid="work-items-limit-error"
      >
        {{ $options.i18n.maxItemsErrorMessage }}
      </div>
    </div>
    <div class="gl-flex gl-gap-3">
      <gl-button
        category="primary"
        variant="confirm"
        size="small"
        type="submit"
        :disabled="!canSubmitForm"
        :loading="submitInProgress"
        data-testid="add-child-button"
      >
        {{ addOrCreateButtonLabel }}
      </gl-button>
      <gl-button category="secondary" size="small" @click="closeForm">
        {{ s__('WorkItem|Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
