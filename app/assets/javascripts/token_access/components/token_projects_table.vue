<script>
import { GlButton, GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    emptyText: s__('CI/CD|No projects have been added to the scope'),
  },
  components: {
    GlButton,
    GlTable,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  props: {
    projects: {
      type: Array,
      required: true,
    },
    tableFields: {
      type: Array,
      required: true,
    },
  },
  methods: {
    removeProject(project) {
      this.$emit('removeProject', project);
    },
  },
};
</script>
<template>
  <gl-table
    :items="projects"
    :fields="tableFields"
    :tbody-tr-attr="{ 'data-testid': 'projects-token-table-row' }"
    :empty-text="$options.i18n.emptyText"
    show-empty
    stacked="sm"
    fixed
  >
    <template #table-colgroup="{ fields }">
      <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
    </template>

    <template #cell(project)="{ item }">
      <span data-testid="token-access-project-name">{{ item.fullPath }}</span>
    </template>

    <template #cell(actions)="{ item }">
      <gl-button
        v-if="item.fullPath !== fullPath"
        category="primary"
        variant="danger"
        icon="remove"
        :aria-label="__('Remove access')"
        @click="removeProject(item.fullPath)"
      />
    </template>
  </gl-table>
</template>
