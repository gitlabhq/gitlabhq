<script>
import { GlAlert, GlFormGroup, GlForm, GlFormCombobox, GlButton, GlFormInput } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import projectWorkItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import createWorkItemMutation from '../../graphql/create_work_item.mutation.graphql';
import { TASK_TYPE_NAME } from '../../constants';

export default {
  components: {
    GlAlert,
    GlForm,
    GlFormCombobox,
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
  },
  data() {
    return {
      availableWorkItems: [],
      search: '',
      error: null,
      childToCreateTitle: null,
    };
  },
  computed: {
    workItemsMvc2Enabled() {
      return this.glFeatures.workItemsMvc2;
    },
    actionsList() {
      return [
        {
          label: this.$options.i18n.createChildOptionLabel,
          fn: () => {
            this.childToCreateTitle = this.search?.title || this.search;
          },
        },
      ];
    },
    addOrCreateButtonLabel() {
      return this.childToCreateTitle
        ? this.$options.i18n.createChildOptionLabel
        : this.$options.i18n.addTaskButtonLabel;
    },
    addOrCreateMethod() {
      return this.childToCreateTitle ? this.createChild : this.addChild;
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
  },
  methods: {
    getIdFromGraphQLId,
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
                childrenIds: [this.search.id],
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemUpdate?.errors?.length) {
            [this.error] = data.workItemUpdate.errors;
          } else {
            this.unsetError();
            this.$emit('addWorkItemChild', this.search);
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
            input: {
              title: this.search?.title || this.search,
              projectPath: this.projectPath,
              workItemTypeId: this.taskWorkItemType,
              hierarchyWidget: {
                parentId: this.issuableGid,
              },
              confidential: this.parentConfidential,
            },
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
  },
  i18n: {
    inputLabel: __('Title'),
    addTaskButtonLabel: s__('WorkItem|Add task'),
    addChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to add a child. Please try again.',
    ),
    createChildOptionLabel: s__('WorkItem|Create task'),
    createChildErrorMessage: s__(
      'WorkItem|Something went wrong when trying to create a child. Please try again.',
    ),
    placeholder: s__('WorkItem|Add a title'),
    fieldValidationMessage: __('Maximum of 255 characters'),
  },
};
</script>

<template>
  <gl-form
    class="gl-bg-white gl-mb-3 gl-p-4 gl-border gl-border-gray-100 gl-rounded-base"
    @submit.prevent="createChild"
  >
    <gl-alert v-if="error" variant="danger" class="gl-mb-3" @dismiss="unsetError">
      {{ error }}
    </gl-alert>
    <!-- Follow up issue to turn this functionality back on https://gitlab.com/gitlab-org/gitlab/-/issues/368757 -->
    <gl-form-combobox
      v-if="false"
      v-model="search"
      :token-list="availableWorkItems"
      match-value-to-attr="title"
      class="gl-mb-4"
      :label-text="$options.i18n.inputLabel"
      :action-list="actionsList"
      label-sr-only
      autofocus
    >
      <template #result="{ item }">
        <div class="gl-display-flex">
          <div class="gl-text-secondary gl-mr-4">{{ getIdFromGraphQLId(item.id) }}</div>
          <div>{{ item.title }}</div>
        </div>
      </template>
      <template #action="{ item }">
        <span class="gl-text-blue-500">{{ item.label }}</span>
      </template>
    </gl-form-combobox>
    <gl-form-group
      :label="$options.i18n.inputLabel"
      :description="$options.i18n.fieldValidationMessage"
    >
      <gl-form-input
        ref="wiTitleInput"
        v-model="search"
        :placeholder="$options.i18n.placeholder"
        maxlength="255"
        class="gl-mb-3"
        autofocus
      />
    </gl-form-group>
    <gl-button
      category="primary"
      variant="confirm"
      size="small"
      type="submit"
      :disabled="search.length === 0"
      data-testid="add-child-button"
      class="gl-mr-2"
    >
      {{ $options.i18n.createChildOptionLabel }}
    </gl-button>
    <gl-button category="secondary" size="small" @click="$emit('cancel')">
      {{ s__('WorkItem|Cancel') }}
    </gl-button>
  </gl-form>
</template>
