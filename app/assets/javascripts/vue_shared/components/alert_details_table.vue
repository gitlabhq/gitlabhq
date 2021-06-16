<script>
import { GlLink, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { reduce } from 'lodash';
import {
  capitalizeFirstCharacter,
  convertToSentenceCase,
  splitCamelCase,
} from '~/lib/utils/text_utility';
import { isSafeURL } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { PAGE_CONFIG } from '~/vue_shared/alert_details/constants';

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
  'hosts',
  'environment',
];

export default {
  components: {
    GlLink,
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
    statuses: {
      type: Object,
      required: false,
      default: () => PAGE_CONFIG.OPERATIONS.STATUSES,
    },
  },
  fields: [
    {
      key: 'fieldName',
      label: s__('AlertManagement|Key'),
      thClass,
      tdClass,
      formatter: (string) =>
        capitalizeFirstCharacter(convertToSentenceCase(splitCamelCase(string))),
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
      return reduce(
        this.alert,
        (allowedItems, fieldValue, fieldName) => {
          if (this.isAllowed(fieldName)) {
            let value;
            if (fieldName === 'environment') {
              value = fieldValue?.name;
            } else if (fieldName === 'status') {
              value = this.statuses[fieldValue] || fieldValue;
            } else {
              value = fieldValue;
            }
            return [...allowedItems, { fieldName, value }];
          }
          return allowedItems;
        },
        [],
      );
    },
  },
  methods: {
    isAllowed(fieldName) {
      return allowedFields.includes(fieldName);
    },
    isValidLink(value) {
      return typeof value === 'string' && isSafeURL(value);
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
    <template #cell(value)="{ item: { value } }">
      <span v-if="!isValidLink(value)">{{ value }}</span>
      <gl-link v-else :href="value" target="_blank">
        {{ value }}
      </gl-link>
    </template>
  </gl-table>
</template>
