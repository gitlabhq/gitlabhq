<script>
import { GlDrawer, GlIcon, GlLink } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/ci/reports/codequality_report/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';

export const i18n = {
  severity: s__('FindingsDrawer|Severity:'),
  engine: s__('FindingsDrawer|Engine:'),
  category: s__('FindingsDrawer|Category:'),
  otherLocations: s__('FindingsDrawer|Other locations:'),
};

export default {
  i18n,
  components: { GlDrawer, GlIcon, GlLink },
  directives: {
    SafeHtml,
  },
  props: {
    drawer: {
      type: Object,
      required: true,
    },
  },
  safeHtmlConfig: {
    ALLOWED_TAGS: ['a', 'h1', 'h2', 'p'],
    ALLOWED_ATTR: ['href', 'rel'],
  },
  computed: {
    drawerOffsetTop() {
      return getContentWrapperHeight('.content-wrapper');
    },
  },
  DRAWER_Z_INDEX,
  methods: {
    severityClass(severity) {
      return SEVERITY_CLASSES[severity] || SEVERITY_CLASSES.unknown;
    },
    severityIcon(severity) {
      return SEVERITY_ICONS[severity] || SEVERITY_ICONS.unknown;
    },
  },
};
</script>
<template>
  <gl-drawer
    :header-height="drawerOffsetTop"
    :z-index="$options.DRAWER_Z_INDEX"
    class="findings-drawer"
    :open="Object.keys(drawer).length !== 0"
    @close="$emit('close')"
  >
    <template #title>
      <h2 data-testid="findings-drawer-heading" class="gl-font-size-h2 gl-mt-0 gl-mb-0">
        {{ drawer.description }}
      </h2>
    </template>

    <template #default>
      <ul class="gl-list-style-none gl-border-b-initial gl-mb-0 gl-pb-0!">
        <li data-testid="findings-drawer-severity" class="gl-mb-4">
          <span class="gl-font-weight-bold">{{ $options.i18n.severity }}</span>
          <gl-icon
            data-testid="findings-drawer-severity-icon"
            :size="12"
            :name="severityIcon(drawer.severity)"
            :class="severityClass(drawer.severity)"
            class="codequality-severity-icon"
          />

          {{ drawer.severity }}
        </li>
        <li data-testid="findings-drawer-engine" class="gl-mb-4">
          <span class="gl-font-weight-bold">{{ $options.i18n.engine }}</span>
          {{ drawer.engineName }}
        </li>
        <li data-testid="findings-drawer-category" class="gl-mb-4">
          <span class="gl-font-weight-bold">{{ $options.i18n.category }}</span>
          {{ drawer.categories ? drawer.categories[0] : '' }}
        </li>
        <li data-testid="findings-drawer-other-locations" class="gl-mb-4">
          <span class="gl-font-weight-bold gl-mb-3 gl-display-block">{{
            $options.i18n.otherLocations
          }}</span>
          <ul class="gl-pl-6">
            <li
              v-for="otherLocation in drawer.otherLocations"
              :key="otherLocation.path"
              class="gl-mb-1"
            >
              <gl-link
                data-testid="findings-drawer-other-locations-link"
                :href="otherLocation.href"
                >{{ otherLocation.path }}</gl-link
              >
            </li>
          </ul>
        </li>
      </ul>
      <span
        v-safe-html:[$options.safeHtmlConfig]="drawer.content ? drawer.content.body : ''"
        data-testid="findings-drawer-body"
        class="drawer-body gl-display-block gl-px-3 gl-py-0!"
      ></span>
    </template>
  </gl-drawer>
</template>
