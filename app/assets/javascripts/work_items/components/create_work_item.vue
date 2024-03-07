<script>
import { GlButton, GlAlert, GlLoadingIcon, GlFormSelect } from '@gitlab/ui';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { getPreferredLocales, s__ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import {
  I18N_WORK_ITEM_CREATE_BUTTON_LABEL,
  I18N_WORK_ITEM_ERROR_CREATING,
  I18N_WORK_ITEM_ERROR_FETCHING_TYPES,
  sprintfWorkItem,
} from '../constants';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';
import groupWorkItemTypesQuery from '../graphql/group_work_item_types.query.graphql';
import projectWorkItemTypesQuery from '../graphql/project_work_item_types.query.graphql';
import groupWorkItemByIidQuery from '../graphql/group_work_item_by_iid.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';

import WorkItemTitleWithEdit from './work_item_title_with_edit.vue';

export default {
  components: {
    GlButton,
    GlAlert,
    GlLoadingIcon,
    WorkItemTitleWithEdit,
    GlFormSelect,
  },
  inject: ['fullPath', 'isGroup'],
  props: {
    initialTitle: {
      type: String,
      required: false,
      default: '',
    },
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      title: this.initialTitle,
      editingTitle: false,
      error: null,
      workItemTypes: [],
      selectedWorkItemType: null,
      loading: false,
      showWorkItemTypeSelect: false,
    };
  },
  apollo: {
    workItemTypes: {
      query() {
        return this.isGroup ? groupWorkItemTypesQuery : projectWorkItemTypesQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          name: this.workItemType,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes.map((node) => ({
          value: node.id,
          text: capitalizeFirstCharacter(node.name.toLocaleLowerCase(getPreferredLocales()[0])),
        }));
      },
      result() {
        if (this.workItemTypes.length === 1) {
          this.selectedWorkItemType = this.workItemTypes[0].value;
        } else {
          this.showWorkItemTypeSelect = true;
        }
      },
      error() {
        this.error = I18N_WORK_ITEM_ERROR_FETCHING_TYPES;
      },
    },
  },
  computed: {
    formOptions() {
      return [{ value: null, text: s__('WorkItem|Select type') }, ...this.workItemTypes];
    },
    isButtonDisabled() {
      return this.title.trim().length === 0 || !this.selectedWorkItemType;
    },
    createErrorText() {
      const workItemType = this.workItemTypes.find(
        (item) => item.value === this.selectedWorkItemType,
      )?.text;

      return sprintfWorkItem(I18N_WORK_ITEM_ERROR_CREATING, workItemType);
    },
    createWorkItemText() {
      const workItemType = this.workItemTypes.find(
        (item) => item.value === this.selectedWorkItemType,
      )?.text;
      return sprintfWorkItem(I18N_WORK_ITEM_CREATE_BUTTON_LABEL, workItemType);
    },
  },
  methods: {
    async createWorkItem() {
      this.loading = true;

      try {
        const response = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              title: this.title,
              projectPath: this.fullPath,
              workItemTypeId: this.selectedWorkItemType,
            },
          },
          update: (store, { data: { workItemCreate } }) => {
            const { workItem } = workItemCreate;

            store.writeQuery({
              query: this.isGroup ? groupWorkItemByIidQuery : workItemByIidQuery,
              variables: {
                fullPath: this.fullPath,
                iid: workItem.iid,
              },
              data: {
                workspace: {
                  __typename: TYPENAME_PROJECT,
                  id: workItem.namespace.id,
                  workItems: {
                    __typename: 'WorkItemConnection',
                    nodes: [workItem],
                  },
                },
              },
            });
          },
        });

        this.$emit('workItemCreated', response.data.workItemCreate.workItem);
      } catch {
        this.error = this.createErrorText;
        this.loading = false;
      }
    },
    handleTitleInput(title) {
      this.title = title;
    },
    handleCancelClick() {
      this.$emit('cancel');
    },
  },
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
    <gl-alert v-if="error" variant="danger" @dismiss="error = null">{{ error }}</gl-alert>
    <div data-testid="content">
      <work-item-title-with-edit
        ref="title"
        data-testid="title-input"
        is-editing
        :title="title"
        @updateDraft="handleTitleInput"
        @updateWorkItem="createWorkItem"
      />
      <div>
        <gl-loading-icon
          v-if="$apollo.queries.workItemTypes.loading"
          size="lg"
          data-testid="loading-types"
        />
        <gl-form-select
          v-else-if="showWorkItemTypeSelect"
          v-model="selectedWorkItemType"
          :options="formOptions"
          class="gl-max-w-26"
        />
      </div>
    </div>
    <div class="gl-py-5 gl-mt-4 gl-display-flex gl-justify-content-end gl-gap-3">
      <gl-button type="button" data-testid="cancel-button" @click="handleCancelClick">
        {{ __('Cancel') }}
      </gl-button>
      <gl-button
        variant="confirm"
        :disabled="isButtonDisabled"
        :loading="loading"
        data-testid="create-button"
        type="submit"
      >
        {{ createWorkItemText }}
      </gl-button>
    </div>
  </form>
</template>
