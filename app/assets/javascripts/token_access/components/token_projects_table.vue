<script>
import { GlButton, GlTable } from '@gitlab/ui';
import { __, s__ } from '~/locale';

const defaultTableClasses = {
  thClass: 'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-100! gl-p-5! gl-border-b-1!',
};

export default {
  i18n: {
    emptyText: s__('CI/CD|No projects have been added to the scope'),
  },
  fields: [
    {
      key: 'project',
      label: __('Projects that can be accessed'),
      tdClass: 'gl-p-5!',
      ...defaultTableClasses,
      columnClass: 'gl-w-85p',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-p-5! gl-text-right',
      ...defaultTableClasses,
      columnClass: 'gl-w-15p',
    },
  ],
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
    :fields="$options.fields"
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
      {{ item.name }}
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
