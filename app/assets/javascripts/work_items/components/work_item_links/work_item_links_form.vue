<script>
import { GlAlert, GlForm, GlFormCombobox, GlButton } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';

export default {
  components: {
    GlAlert,
    GlForm,
    GlFormCombobox,
    GlButton,
  },
  inject: ['projectPath'],
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
  },
  apollo: {
    availableWorkItems: {
      query: projectWorkItemsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          searchTerm: this.search?.title || this.search,
          types: ['TASK'],
        };
      },
      skip() {
        return this.search.length === 0;
      },
      update(data) {
        return data.workspace.workItems.edges
          .filter((wi) => !this.childrenIds.includes(wi.node.id))
          .map((wi) => wi.node);
      },
    },
  },
  data() {
    return {
      availableWorkItems: [],
      search: '',
      error: null,
    };
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
          this.error = this.$options.i18n.errorMessage;
        })
        .finally(() => {
          this.search = '';
        });
    },
  },
  i18n: {
    inputLabel: __('Children'),
    errorMessage: s__(
      'WorkItem|Something went wrong when trying to add a child. Please try again.',
    ),
  },
};
</script>

<template>
  <gl-form
    class="gl-mb-3 gl-bg-white gl-mb-3 gl-py-3 gl-px-4 gl-border gl-border-gray-100 gl-rounded-base"
  >
    <gl-alert v-if="error" variant="danger" class="gl-mb-3" @dismiss="unsetError">
      {{ error }}
    </gl-alert>
    <gl-form-combobox
      v-model="search"
      :token-list="availableWorkItems"
      match-value-to-attr="title"
      class="gl-mb-4"
      :label-text="$options.i18n.inputLabel"
      label-sr-only
      autofocus
    >
      <template #result="{ item }">
        <div class="gl-display-flex">
          <div class="gl-text-gray-400 gl-mr-4">{{ getIdFromGraphQLId(item.id) }}</div>
          <div>{{ item.title }}</div>
        </div>
      </template>
    </gl-form-combobox>
    <gl-button category="secondary" data-testid="add-child-button" @click="addChild">
      {{ s__('WorkItem|Add task') }}
    </gl-button>
    <gl-button category="tertiary" @click="$emit('cancel')">
      {{ s__('WorkItem|Cancel') }}
    </gl-button>
  </gl-form>
</template>
