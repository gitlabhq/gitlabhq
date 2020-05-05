<script>
import { GlNewDropdown, GlNewDropdownItem, GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';

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
};
</script>
<template>
  <div>
    <div class="d-flex justify-content-between border-bottom pb-2 pt-1">
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
    <div class="d-flex">
      <gl-tabs>
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
  </div>
</template>
