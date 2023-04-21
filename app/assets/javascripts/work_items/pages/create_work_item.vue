<script>
import { GlButton, GlAlert, GlLoadingIcon, GlFormSelect } from '@gitlab/ui';
import { getPreferredLocales, s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { sprintfWorkItem, I18N_WORK_ITEM_ERROR_CREATING } from '../constants';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';
import projectWorkItemTypesQuery from '../graphql/project_work_item_types.query.graphql';
import { getWorkItemQuery } from '../utils';

import ItemTitle from '../components/item_title.vue';

export default {
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
  mixins: [glFeatureFlagMixin()],
  inject: ['fullPath'],
  props: {
    initialTitle: {
      type: String,
      required: false,
      default: '',
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
          text: capitalizeFirstCharacter(node.name.toLocaleLowerCase(getPreferredLocales()[0])),
        }));
      },
      error() {
        this.error = this.$options.fetchTypesErrorText;
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
    fetchByIid() {
      return true;
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
          update: (store, { data: { workItemCreate } }) => {
            const { workItem } = workItemCreate;
            const data = this.fetchByIid
              ? {
                  workspace: {
                    // eslint-disable-next-line @gitlab/require-i18n-strings
                    __typename: 'Project',
                    id: workItem.project.id,
                    workItems: {
                      __typename: 'WorkItemConnection',
                      nodes: [workItem],
                    },
                  },
                }
              : { workItem };

            store.writeQuery({
              query: getWorkItemQuery(this.fetchByIid),
              variables: this.fetchByIid
                ? {
                    fullPath: this.fullPath,
                    iid: workItem.iid,
                  }
                : {
                    id: workItem.id,
                  },
              data,
            });
          },
        });
        const {
          data: {
            workItemCreate: {
              workItem: { id, iid },
            },
          },
        } = response;
        const routerParams = this.fetchByIid
          ? { name: 'workItem', params: { id: iid } }
          : { name: 'workItem', params: { id: `${getIdFromGraphQLId(id)}` } };
        this.$router.push(routerParams);
      } catch {
        this.error = this.createErrorText;
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
