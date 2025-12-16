<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'WorkItemsSavedViewsSelectors',
  components: {
    GlTabs,
    GlTab,
  },
  i18n: {
    defaultViewtitle: s__('WorkItem|All items'),
  },
};
</script>

<template>
  <div class="saved-views-selectors gl-flex gl-flex-row gl-flex-nowrap gl-justify-between">
    <gl-tabs class="gl-m-0 gl-grow gl-p-0">
      <gl-tab>
        <template #title>
          <span data-testid="saved-views-default-view-selector">{{
            $options.i18n.defaultViewtitle
          }}</span>
        </template>
      </gl-tab>
    </gl-tabs>
    <div class="gl-border-b !gl-flex gl-items-center gl-justify-end gl-gap-3">
      <slot name="header-area"></slot>
    </div>
  </div>
</template>
