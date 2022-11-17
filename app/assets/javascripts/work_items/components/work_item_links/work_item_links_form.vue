<script>
import { GlAlert, GlFormGroup, GlForm, GlTokenSelector, GlButton, GlFormInput } from '@gitlab/ui';
import { debounce } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import createWorkItemMutation from '../../graphql/create_work_item.mutation.graphql';
import { FORM_TYPES, TASK_TYPE_NAME } from '../../constants';

export default {
  components: {
    GlAlert,
    GlForm,
    GlTokenSelector,
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['projectPath', 'hasIterationsFeature'],
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
  },
  apollo: {
    workItemTypes: {
      query: projectWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.projectPath,
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
          projectPath: this.projectPath,
          searchTerm: this.search?.title || this.search,
          types: ['TASK'],
          in: this.search ? 'TITLE' : undefined,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace.workItems.nodes.filter((wi) => !this.childrenIds.includes(wi.id));
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
    };
  },
  computed: {
    workItemInput() {
      let workItemInput = {
        title: this.search?.title || this.search,
        projectPath: this.projectPath,
        workItemTypeId: this.taskWorkItemType,
        hierarchyWidget: {
          parentId: this.issuableGid,
        },
        confidential: this.parentConfidential,
      };

      if (this.associateMilestone) {
        workItemInput = {
          ...workItemInput,
          milestoneWidget: {
            milestoneId: this.parentMilestoneId,
          },
        };
      }
      return workItemInput;
    },
    workItemsMvc2Enabled() {
      return this.glFeatures.workItemsMvc2;
    },
    isCreateForm() {
      return this.formType === FORM_TYPES.create;
    },
    addOrCreateButtonLabel() {
      if (this.isCreateForm) {
        return this.$options.i18n.createChildOptionLabel;
      } else if (this.workItemsToAdd.length > 1) {
        return this.$options.i18n.addTasksButtonLabel;
      }
      return this.$options.i18n.addTaskButtonLabel;
    },
    addOrCreateMethod() {
      return this.isCreateForm ? this.createChild : this.addChild;
    },
    taskWorkItemType() {
      return this.workItemTypes.find((type) => type.name === TASK_TYPE_NAME)?.id;
    },
    parentIterationId() {
      return this.parentIteration?.id;
    },
    associateIteration() {
      return this.parentIterationId && this.hasIterationsFeature && this.workItemsMvc2Enabled;
    },
    parentMilestoneId() {
      return this.parentMilestone?.id;
    },
    associateMilestone() {
      return this.parentMilestoneId && this.workItemsMvc2Enabled;
    },
    isSubmitButtonDisabled() {
      return this.isCreateForm ? this.search.length === 0 : this.workItemsToAdd.length === 0;
    },
    isLoading() {
      return this.$apollo.queries.availableWorkItems.loading;
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    getIdFromGraphQLId,
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
            /**
             * call update mutation only when there is an iteration associated with the issue
             */
            // TODO: setting the iteration should be moved to the creation mutation once the backend is done
            if (this.associateIteration) {
              this.addIterationToWorkItem(data.workItemCreate.workItem.id);
            }
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
    async addIterationToWorkItem(workItemId) {
      await this.$apollo.mutate({
        mutation: updateWorkItemMutation,
        variables: {
          input: {
            id: workItemId,
            iterationWidget: {
              iterationId: this.parentIterationId,
            },
          },
        },
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
    addTaskButtonLabel: s__('WorkItem|Add task'),
    addTasksButtonLabel: s__('WorkItem|Add tasks'),
    addChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to add a child. Please try again.',
    ),
    createChildOptionLabel: s__('WorkItem|Create task'),
    createChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to create a child. Please try again.',
    ),
    createPlaceholder: s__('WorkItem|Add a title'),
    addPlaceholder: s__('WorkItem|Search existing tasks'),
    fieldValidationMessage: __('Maximum of 255 characters'),
  },
};
</script>

<template>
  <gl-form
    class="gl-bg-white gl-mb-3 gl-p-4 gl-border gl-border-gray-100 gl-rounded-base"
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
    <gl-token-selector
      v-else
      v-model="workItemsToAdd"
      :dropdown-items="availableWorkItems"
      :loading="isLoading"
      :placeholder="$options.i18n.addPlaceholder"
      menu-class="gl-dropdown-menu-wide dropdown-reduced-height gl-min-h-7!"
      class="gl-mb-4"
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
