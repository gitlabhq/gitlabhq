<script>
import {
  GlAlert,
  GlFormGroup,
  GlForm,
  GlButton,
  GlFormInput,
  GlFormCheckbox,
  GlTooltip,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import WorkItemTokenInput from '../shared/work_item_token_input.vue';
import { addHierarchyChild } from '../../graphql/cache_utils';
import groupWorkItemTypesQuery from '../../graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '../../graphql/project_work_item_types.query.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
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
  sprintfWorkItem,
} from '../../constants';

export default {
  components: {
    GlAlert,
    GlForm,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    GlTooltip,
    WorkItemTokenInput,
  },
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
        return this.isGroup ? groupWorkItemTypesQuery : projectWorkItemTypesQuery;
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
      search: '',
      childToCreateTitle: null,
      confidential: this.parentConfidential,
    };
  },
  computed: {
    workItemInput() {
      let workItemInput = {
        title: this.search?.title || this.search,
        projectPath: this.fullPath,
        workItemTypeId: this.childWorkItemType,
        hierarchyWidget: {
          parentId: this.issuableGid,
        },
        confidential: this.parentConfidential || this.confidential,
      };

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
    isSubmitButtonDisabled() {
      if (this.isCreateForm) {
        return this.search.length === 0;
      }
      return this.workItemsToAdd.length === 0 || !this.areWorkItemsToAddValid;
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
  methods: {
    getConfidentialityTooltipTarget() {
      // We want tooltip to be anchored to `input` within checkbox component
      // but `$el.querySelector('input')` doesn't work. 🤷‍♂️
      return this.$refs.confidentialityCheckbox?.$el;
    },
    unsetError() {
      this.error = null;
    },
    addChild() {
      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
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
        })
        .finally(() => {
          this.search = '';
        });
    },
    createChild() {
      this.$apollo
        .mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: this.workItemInput,
          },
          update: (cache, { data }) =>
            addHierarchyChild({
              cache,
              fullPath: this.fullPath,
              iid: this.workItemIid,
              isGroup: this.isGroup,
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
        })
        .finally(() => {
          this.search = '';
          this.childToCreateTitle = null;
        });
    },
  },
  i18n: {
    inputLabel: __('Title'),
    addChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to add a child. Please try again.',
    ),
    createChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to create a child. Please try again.',
    ),
    createPlaceholder: s__('WorkItem|Add a title'),
    fieldValidationMessage: __('Maximum of 255 characters'),
  },
};
</script>

<template>
  <gl-form
    class="gl-new-card-add-form"
    data-testid="add-item-form"
    @submit.prevent="addOrCreateMethod"
  >
    <gl-alert v-if="error" variant="danger" class="gl-mb-3" @dismiss="unsetError">
      {{ error }}
    </gl-alert>
    <gl-form-group
      v-if="isCreateForm"
      :label="$options.i18n.inputLabel"
      :description="$options.i18n.fieldValidationMessage"
    >
      <gl-form-input
        ref="wiTitleInput"
        v-model="search"
        :placeholder="$options.i18n.createPlaceholder"
        maxlength="255"
        class="gl-mb-3"
        autofocus
      />
    </gl-form-group>
    <gl-form-checkbox
      v-if="isCreateForm"
      ref="confidentialityCheckbox"
      v-model="confidential"
      name="isConfidential"
      class="gl-md-mt-5 gl-mb-5 gl-md-mb-3!"
      :disabled="parentConfidential"
      >{{ confidentialityCheckboxLabel }}</gl-form-checkbox
    >
    <gl-tooltip
      v-if="showConfidentialityTooltip"
      :target="getConfidentialityTooltipTarget"
      triggers="hover"
      >{{ confidentialityCheckboxTooltip }}</gl-tooltip
    >
    <div class="gl-mb-4">
      <work-item-token-input
        v-if="!isCreateForm"
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
    </div>
    <gl-button
      category="primary"
      variant="confirm"
      size="small"
      type="submit"
      :disabled="isSubmitButtonDisabled"
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
