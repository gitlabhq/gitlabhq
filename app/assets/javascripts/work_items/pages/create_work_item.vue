<script>
import { GlButton, GlAlert, GlLoadingIcon, GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import workItemQuery from '../graphql/work_item.query.graphql';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';
import createWorkItemFromTaskMutation from '../graphql/create_work_item_from_task.mutation.graphql';
import projectWorkItemTypesQuery from '../graphql/project_work_item_types.query.graphql';

import ItemTitle from '../components/item_title.vue';

export default {
  createErrorText: s__('WorkItem|Something went wrong when creating a task. Please try again'),
  fetchTypesErrorText: s__(
    'WorkItem|Something went wrong when fetching work item types. Please try again',
  ),
  components: {
    GlButton,
    GlAlert,
    GlLoadingIcon,
    ItemTitle,
    GlFormSelect,
  },
  inject: ['fullPath'],
  props: {
    initialTitle: {
      type: String,
      required: false,
      default: '',
    },
    issueGid: {
      type: String,
      required: false,
      default: '',
    },
    lockVersion: {
      type: Number,
      required: false,
      default: null,
    },
    lineNumberStart: {
      type: String,
      required: false,
      default: null,
    },
    lineNumberEnd: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      title: this.initialTitle,
      error: null,
      workItemTypes: [],
      selectedWorkItemType: null,
      loading: false,
    };
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
        return data.workspace?.workItemTypes?.nodes.map((node) => ({
          value: node.id,
          text: node.name,
        }));
      },
      error() {
        this.error = this.$options.fetchTypesErrorText;
      },
    },
  },
  computed: {
    dropdownButtonText() {
      return this.selectedWorkItemType?.name || s__('WorkItem|Type');
    },
    formOptions() {
      return [{ value: null, text: s__('WorkItem|Select type') }, ...this.workItemTypes];
    },
    isButtonDisabled() {
      return this.title.trim().length === 0 || !this.selectedWorkItemType;
    },
  },
  methods: {
    async createWorkItem() {
      this.loading = true;
      await this.createStandaloneWorkItem();
      this.loading = false;
    },
    async createStandaloneWorkItem() {
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
          update(store, { data: { workItemCreate } }) {
            const { workItem } = workItemCreate;

            store.writeQuery({
              query: workItemQuery,
              variables: {
                id: workItem.id,
              },
              data: {
                workItem,
              },
            });
          },
        });
        const {
          data: {
            workItemCreate: {
              workItem: { id },
            },
          },
        } = response;
        this.$router.push({ name: 'workItem', params: { id: `${getIdFromGraphQLId(id)}` } });
      } catch {
        this.error = this.$options.createErrorText;
      }
    },
    async createWorkItemFromTask() {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: createWorkItemFromTaskMutation,
          variables: {
            input: {
              id: this.issueGid,
              workItemData: {
                lockVersion: this.lockVersion,
                title: this.title,
                lineNumberStart: Number(this.lineNumberStart),
                lineNumberEnd: Number(this.lineNumberEnd),
                workItemTypeId: this.selectedWorkItemType,
              },
            },
          },
        });
        this.$emit('onCreate', data.workItemCreateFromTask.workItem.descriptionHtml);
      } catch {
        this.error = this.$options.createErrorText;
      }
    },
    handleTitleInput(title) {
      this.title = title;
    },
    handleCancelClick() {
      this.$router.go(-1);
    },
  },
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
    <gl-alert v-if="error" variant="danger" @dismiss="error = null">{{ error }}</gl-alert>
    <div data-testid="content">
      <item-title :title="initialTitle" data-testid="title-input" @title-input="handleTitleInput" />
      <div>
        <gl-loading-icon
          v-if="$apollo.queries.workItemTypes.loading"
          size="lg"
          data-testid="loading-types"
        />
        <gl-form-select
          v-else
          v-model="selectedWorkItemType"
          :options="formOptions"
          class="gl-max-w-26"
        />
      </div>
    </div>
    <div class="gl-bg-gray-10 gl-py-5 gl-px-6 gl-mt-4">
      <gl-button
        variant="confirm"
        :disabled="isButtonDisabled"
        class="gl-mr-3"
        :loading="loading"
        data-testid="create-button"
        type="submit"
      >
        {{ s__('WorkItem|Create work item') }}
      </gl-button>
      <gl-button
        type="button"
        data-testid="cancel-button"
        class="gl-order-n1"
        @click="handleCancelClick"
      >
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
