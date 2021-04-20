<script>
import { GlTable } from '@gitlab/ui';
import { __ } from '~/locale';

const defaultTableClasses = {
  tdClass: 'gl-p-5!',
  thClass: 'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-100! gl-p-5! gl-border-b-1!',
};

export default {
  fields: [
    {
      key: 'status',
      label: __('Status'),
      ...defaultTableClasses,
    },
    {
      key: 'job',
      label: __('Job'),
      ...defaultTableClasses,
    },
    {
      key: 'pipeline',
      label: __('Pipeline'),
      ...defaultTableClasses,
    },
    {
      key: 'stage',
      label: __('Stage'),
      ...defaultTableClasses,
    },
    {
      key: 'name',
      label: __('Name'),
      ...defaultTableClasses,
    },
    {
      key: 'duration',
      label: __('Duration'),
      ...defaultTableClasses,
    },
    {
      key: 'coverage',
      label: __('Coverage'),
      ...defaultTableClasses,
    },
    {
      key: 'actions',
      label: '',
      ...defaultTableClasses,
    },
  ],
  components: {
    GlTable,
  },
  props: {
    jobs: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <gl-table :items="jobs" :fields="$options.fields" />
</template>
