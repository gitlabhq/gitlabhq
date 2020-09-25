<script>
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  capitalizeFirstCharacter,
  convertToSentenceCase,
  splitCamelCase,
} from '~/lib/utils/text_utility';

const thClass = 'gl-bg-transparent! gl-border-1! gl-border-b-solid! gl-border-gray-200!';
const tdClass = 'gl-border-gray-100! gl-p-5!';
const allowedFields = [
  'iid',
  'title',
  'severity',
  'status',
  'startedAt',
  'eventCount',
  'monitoringTool',
  'service',
  'description',
  'endedAt',
  'details',
];

const filterAllowedFields = ([fieldName]) => allowedFields.includes(fieldName);
const arrayToObject = ([fieldName, value]) => ({ fieldName, value });

export default {
  components: {
    GlLoadingIcon,
    GlTable,
  },
  props: {
    alert: {
      type: Object,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  fields: [
    {
      key: 'fieldName',
      label: s__('AlertManagement|Key'),
      thClass,
      tdClass,
      formatter: string => capitalizeFirstCharacter(convertToSentenceCase(splitCamelCase(string))),
    },
    {
      key: 'value',
      thClass: `${thClass} w-60p`,
      tdClass,
      label: s__('AlertManagement|Value'),
    },
  ],
  computed: {
    items() {
      if (!this.alert) {
        return [];
      }
      return Object.entries(this.alert)
        .filter(filterAllowedFields)
        .map(arrayToObject);
    },
  },
};
</script>
<template>
  <gl-table
    class="alert-management-details-table"
    :busy="loading"
    :empty-text="s__('AlertManagement|No alert data to display.')"
    :items="items"
    :fields="$options.fields"
    show-empty
  >
    <template #table-busy>
      <gl-loading-icon size="lg" color="dark" class="gl-mt-5" />
    </template>
  </gl-table>
</template>
