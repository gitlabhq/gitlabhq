<script>
import { GlFormGroup, GlForm, GlButton, GlFormInput, GlFormCheckbox, GlTooltip } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkItemTokenInput from '../shared/work_item_token_input.vue';
import { addHierarchyChild } from '../../graphql/cache_utils';
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
  sprintfWorkItem,
} from '../../constants';
import WorkItemProjectsListbox from './work_item_projects_listbox.vue';

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
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['hasIterationsFeature', 'isGroup'],
  props: {
    fullPath: {
      type: String,
      required: true,
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
      default: () => {},
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
      selectedProject: null,
      childToCreateTitle: null,
      confidential: this.parentConfidential,
      submitInProgress: false,
    };
  },
  computed: {
    workItemChildIsEpic() {
      return this.childrenTypeName === WORK_ITEM_TYPE_VALUE_EPIC;
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

      if (this.selectedProject && !this.workItemChildIsEpic) {
        workItemInput = {
          ...workItemInput,
          namespacePath: this.selectedProject.fullPath,
        };
      } else {
        workItemInput = {
          ...workItemInput,
          projectPath: this.fullPath,
        };
      }

      if (this.parentMilestoneId) {
        workItemInput = {
          ...workItemInput,
          milestoneWidget: {
            milestoneId: this.parentMilestoneId,
          },
        };
      }

      if (this.associateIteration) {
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
      return this.selectedProject !== null && this.selectedProject !== undefined;
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
      return this.invalidWorkItemsToAdd.length === 0;
    },
    showWorkItemsToAddInvalidMessage() {
      return !this.isCreateForm && !this.areWorkItemsToAddValid;
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
  },
  watch: {
    workItemsToAdd() {
      this.unsetError();
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
    addChild() {
      this.submitInProgress = true;
      this.$apollo
        .mutate({
          mutation: updateWorkItemHierarchyMutation,
          variables: {
            input: {
              id: this.issuableGid,
              hierarchyWidget: {
                childrenIds: this.workItemsToAdd.map((wi) => wi.id),
              },
            },
          },
        })
        .then(({ data }) => {
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
        })
        .finally(() => {
          this.search = '';
          this.submitInProgress = false;
        });
    },
    createChild() {
      if (!this.canSubmitForm) {
        return;
      }
      this.submitInProgress = true;
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
        })
        .finally(() => {
          this.search = '';
          this.childToCreateTitle = null;
          this.submitInProgress = false;
        });
    },
  },
  i18n: {
    titleInputLabel: __('Title'),
    projectInputLabel: __('Project'),
    addChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to add a child. Please try again.',
    ),
    createChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to create a child. Please try again.',
    ),
    titleInputPlaceholder: s__('WorkItem|Add a title'),
    projectInputPlaceholder: s__('WorkItem|Select a project'),
    titleInputValidationMessage: __('Maximum of 255 characters'),
  },
};
</script>

<template>
  <gl-form
    class="gl-new-card-add-form"
    data-testid="add-item-form"
    @submit.prevent="addOrCreateMethod"
  >
    <template v-if="isCreateForm">
      <div class="gl-display-flex gl-gap-x-3">
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
            v-model="selectedProject"
            class="gl-w-full"
            :full-path="fullPath"
            :is-group="isGroup"
          />
        </gl-form-group>
      </div>
      <gl-form-checkbox
        ref="confidentialityCheckbox"
        v-model="confidential"
        name="isConfidential"
        class="gl-mb-5 gl-md-mb-3!"
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
        :parent-work-item-id="issuableGid"
        :children-type="childrenType"
        :children-ids="childrenIds"
        :are-work-items-to-add-valid="areWorkItemsToAddValid"
        :full-path="fullPath"
      />
      <div
        v-if="showWorkItemsToAddInvalidMessage"
        class="gl-text-red-500"
        data-testid="work-items-invalid"
      >
        {{ workItemsToAddInvalidMessage }}
      </div>
      <div v-if="error" class="gl-text-red-500 gl-mt-3" data-testid="work-items-error">
        {{ error }}
      </div>
    </div>
    <gl-button
      category="primary"
      variant="confirm"
      size="small"
      type="submit"
      :disabled="!canSubmitForm"
      :loading="submitInProgress"
      data-testid="add-child-button"
      class="gl-mr-2"
    >
      {{ addOrCreateButtonLabel }}
    </gl-button>
    <gl-button category="secondary" size="small" @click="$emit('cancel')">
      {{ s__('WorkItem|Cancel') }}
    </gl-button>
  </gl-form>
</template>
