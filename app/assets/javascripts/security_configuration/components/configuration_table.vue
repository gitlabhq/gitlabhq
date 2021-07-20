<script>
import { GlLink, GlTable, GlAlert } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import ManageViaMR from '~/vue_shared/security_configuration/components/manage_via_mr.vue';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_DAST,
  REPORT_TYPE_DAST_PROFILES,
  REPORT_TYPE_DEPENDENCY_SCANNING,
  REPORT_TYPE_CONTAINER_SCANNING,
  REPORT_TYPE_CLUSTER_IMAGE_SCANNING,
  REPORT_TYPE_COVERAGE_FUZZING,
  REPORT_TYPE_API_FUZZING,
  REPORT_TYPE_LICENSE_COMPLIANCE,
} from '~/vue_shared/security_reports/constants';

import { scanners } from './constants';
import Upgrade from './upgrade.vue';

const borderClasses = 'gl-border-b-1! gl-border-b-solid! gl-border-gray-100!';
const thClass = `gl-text-gray-900 gl-bg-transparent! ${borderClasses}`;

export default {
  components: {
    GlLink,
    GlTable,
    GlAlert,
  },
  data() {
    return {
      errorMessage: '',
    };
  },
  methods: {
    getFeatureDocumentationLinkLabel(item) {
      return sprintf(s__('SecurityConfiguration|Feature documentation for %{featureName}'), {
        featureName: item.name,
      });
    },
    onError(value) {
      this.errorMessage = value;
    },
    getComponentForItem(item) {
      const COMPONENTS = {
        [REPORT_TYPE_SAST]: ManageViaMR,
        [REPORT_TYPE_DAST]: Upgrade,
        [REPORT_TYPE_DAST_PROFILES]: Upgrade,
        [REPORT_TYPE_DEPENDENCY_SCANNING]: Upgrade,
        [REPORT_TYPE_CONTAINER_SCANNING]: Upgrade,
        [REPORT_TYPE_CLUSTER_IMAGE_SCANNING]: Upgrade,
        [REPORT_TYPE_COVERAGE_FUZZING]: Upgrade,
        [REPORT_TYPE_API_FUZZING]: Upgrade,
        [REPORT_TYPE_LICENSE_COMPLIANCE]: Upgrade,
      };
      return COMPONENTS[item.type];
    },
  },
  table: {
    fields: [
      {
        key: 'feature',
        label: s__('SecurityConfiguration|Security Control'),
        thClass,
      },
      {
        key: 'manage',
        label: s__('SecurityConfiguration|Manage'),
        thClass,
      },
    ],
    items: scanners,
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <gl-table :items="$options.table.items" :fields="$options.table.fields" stacked="md">
      <template #cell(feature)="{ item }">
        <div class="gl-text-gray-900">
          {{ item.name }}
        </div>
        <div>
          {{ item.description }}
          <gl-link
            target="_blank"
            data-testid="help-link"
            :href="item.helpPath"
            :aria-label="getFeatureDocumentationLinkLabel(item)"
          >
            {{ s__('SecurityConfiguration|More information') }}
          </gl-link>
        </div>
      </template>

      <template #cell(manage)="{ item }">
        <component
          :is="getComponentForItem(item)"
          :feature="item"
          :data-testid="item.type"
          @error="onError"
        />
      </template>
    </gl-table>
  </div>
</template>
