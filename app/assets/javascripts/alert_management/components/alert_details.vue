<script>
import { GlNewDropdown, GlNewDropdownItem, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';
import query from '../graphql/queries/details.query.graphql';
import { fetchPolicies } from '~/lib/graphql';

export default {
  statuses: {
    triggered: s__('AlertManagement|Triggered'),
    acknowledged: s__('AlertManagement|Acknowledged'),
    resolved: s__('AlertManagement|Resolved'),
  },
  i18n: {
    fullAlertDetailsTitle: s__('AlertManagement|Full Alert Details'),
    overviewTitle: s__('AlertManagement|Overview'),
  },
  components: {
    GlNewDropdown,
    GlNewDropdownItem,
    GlTab,
    GlTabs,
  },
  props: {
    alertId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    alert: {
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      query,
      variables() {
        return {
          fullPath: this.projectPath,
          alertId: this.alertId,
        };
      },
      update(data) {
        return data?.project?.alertManagementAlerts?.nodes?.[0] ?? null;
      },
    },
  },
  data() {
    return { alert: null };
  },
};
</script>
<template>
  <div>
    <div v-if="alert" class="d-flex justify-content-between border-bottom pb-2 pt-1">
      <div></div>
      <gl-new-dropdown class="align-self-center" right>
        <gl-new-dropdown-item
          v-for="(label, field) in $options.statuses"
          :key="field"
          data-testid="statusDropdownItem"
          class="align-middle"
          >{{ label }}
        </gl-new-dropdown-item>
      </gl-new-dropdown>
    </div>
    <gl-tabs v-if="alert" data-testid="alertDetailsTabs">
      <gl-tab data-testid="overviewTab" :title="$options.i18n.overviewTitle">
        <ul class="pl-3">
          <li data-testid="startTimeItem" class="font-weight-bold mb-3 mt-2">
            {{ s__('AlertManagement|Start time:') }}
          </li>
          <li class="font-weight-bold my-3">
            {{ s__('AlertManagement|End time:') }}
          </li>
          <li class="font-weight-bold my-3">
            {{ s__('AlertManagement|Events:') }}
          </li>
        </ul>
      </gl-tab>
      <gl-tab data-testid="fullDetailsTab" :title="$options.i18n.fullAlertDetailsTitle" />
    </gl-tabs>
  </div>
</template>
