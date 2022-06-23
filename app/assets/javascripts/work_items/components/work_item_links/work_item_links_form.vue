<script>
import { GlForm, GlFormCombobox, GlButton } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import projectWorkItemsQuery from '../../graphql/project_work_items.query.graphql';

export default {
  components: {
    GlForm,
    GlFormCombobox,
    GlButton,
  },
  inject: ['projectPath'],
  apollo: {
    availableWorkItems: {
      query: projectWorkItemsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          searchTerm: this.search,
        };
      },
      update(data) {
        return data.workspace.workItems.edges.map((wi) => wi.node);
      },
    },
  },
  data() {
    return {
      relatedWorkItem: '',
      availableWorkItems: [],
      search: '',
    };
  },
  methods: {
    getIdFromGraphQLId,
  },
  i18n: {
    inputLabel: __('Children'),
  },
};
</script>

<template>
  <gl-form @submit.prevent>
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
    <gl-button type="submit" category="secondary" variant="confirm">
      {{ s__('WorkItem|Add') }}
    </gl-button>
    <gl-button category="tertiary" class="gl-float-right" @click="$emit('cancel')">
      {{ s__('WorkItem|Cancel') }}
    </gl-button>
  </gl-form>
</template>
