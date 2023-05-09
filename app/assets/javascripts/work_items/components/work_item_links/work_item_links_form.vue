<script>
import {
  GlAlert,
  GlFormGroup,
  GlForm,
  GlTokenSelector,
  GlButton,
  GlFormInput,
  GlFormCheckbox,
  GlTooltip,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__, sprintf } from '~/locale';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import createWorkItemMutation from '../../graphql/create_work_item.mutation.graphql';
import {
  FORM_TYPES,
  WORK_ITEMS_TYPE_MAP,
  WORK_ITEM_TYPE_ENUM_TASK,
  I18N_WORK_ITEM_CREATE_BUTTON_LABEL,
  I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER,
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
    GlTokenSelector,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormCheckbox,
    GlTooltip,
  },
  inject: ['fullPath', 'hasIterationsFeature'],
  props: {
    issuableGid: {
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
      query: projectWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
    },
    availableWorkItems: {
      query: projectWorkItemsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.search?.title || this.search,
          types: [this.childrenType],
          in: this.search ? 'TITLE' : undefined,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace.workItems.nodes.filter(
          (wi) => !this.childrenIds.includes(wi.id) && this.issuableGid !== wi.id,
        );
      },
    },
  },
  data() {
    return {
      workItemTypes: [],
      availableWorkItems: [],
      search: '',
      searchStarted: false,
      error: null,
      childToCreateTitle: null,
      workItemsToAdd: [],
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
      } else if (this.workItemsToAdd.length > 1) {
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
    isLoading() {
      return this.$apollo.queries.availableWorkItems.loading;
    },
    addInputPlaceholder() {
      return sprintfWorkItem(I18N_WORK_ITEM_SEARCH_INPUT_PLACEHOLDER, this.childrenTypeName);
    },
    tokenSelectorContainerClass() {
      return !this.areWorkItemsToAddValid ? 'gl-inset-border-1-red-500!' : '';
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
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    getIdFromGraphQLId,
    getConfidentialityTooltipTarget() {
      // We want tooltip to be anchored to `input` within checkbox component
      // but `$el.querySelector('input')` doesn't work. 🤷‍♂️
      return this.$refs.confidentialityCheckbox?.$el;
    },
    unsetError() {
      this.error = null;
    },
    addChild() {
      this.searchStarted = false;
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
        })
        .then(({ data }) => {
          if (data.workItemCreate?.errors?.length) {
            [this.error] = data.workItemCreate.errors;
          } else {
            this.unsetError();
            this.$emit('addWorkItemChild', data.workItemCreate.workItem);
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
    setSearchKey(value) {
      this.search = value;
    },
    handleFocus() {
      this.searchStarted = true;
    },
    handleMouseOver() {
      this.timeout = setTimeout(() => {
        this.searchStarted = true;
      }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    },
    handleMouseOut() {
      clearTimeout(this.timeout);
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
    class="gl-bg-white gl-mt-1 gl-mb-3 gl-p-4 gl-border gl-border-gray-100 gl-rounded-base"
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
      <gl-token-selector
        v-if="!isCreateForm"
        v-model="workItemsToAdd"
        :dropdown-items="availableWorkItems"
        :loading="isLoading"
        :placeholder="addInputPlaceholder"
        menu-class="gl-dropdown-menu-wide dropdown-reduced-height gl-min-h-7!"
        :container-class="tokenSelectorContainerClass"
        data-testid="work-item-token-select-input"
        @text-input="debouncedSearchKeyUpdate"
        @focus="handleFocus"
        @mouseover.native="handleMouseOver"
        @mouseout.native="handleMouseOut"
      >
        <template #token-content="{ token }">
          {{ token.title }}
        </template>
        <template #dropdown-item-content="{ dropdownItem }">
          <div class="gl-display-flex">
            <div class="gl-text-secondary gl-mr-4">{{ getIdFromGraphQLId(dropdownItem.id) }}</div>
            <div class="gl-text-truncate">{{ dropdownItem.title }}</div>
          </div>
        </template>
      </gl-token-selector>
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
