<script>
import { GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import glFeaturesMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { joinPaths, mergeUrlParams } from '~/lib/utils/url_utility';
import {
  EVENT_LABEL_CLICK_METRIC_IN_DASHBOARD_TABLE,
  VALUE_STREAM_METRIC_METADATA,
} from '~/analytics/shared/constants';
import { s__ } from '~/locale';
import { DATA_TABLE_METRICS } from 'ee_else_ce/analytics/dashboards/constants';

export default {
  name: 'MetricLabel',
  components: {
    GlIcon,
    GlLink,
    GlPopover,
  },
  mixins: [InternalEvents.mixin(), glFeaturesMixin()],
  props: {
    identifier: {
      type: String,
      required: true,
      validator: (key) => Object.keys(VALUE_STREAM_METRIC_METADATA).includes(key),
    },
    requestPath: {
      type: String,
      required: false,
      default: '',
    },
    isProject: {
      type: Boolean,
      required: false,
      default: false,
    },
    filterLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
    trackingProperty: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    metric() {
      return DATA_TABLE_METRICS[this.identifier];
    },
    tooltip() {
      return VALUE_STREAM_METRIC_METADATA[this.identifier];
    },
    link() {
      const { groupLink, projectLink } = this.tooltip;
      const url = joinPaths(
        '/',
        gon.relative_url_root,
        !this.isProject ? 'groups' : '',
        this.requestPath,
        this.isProject ? projectLink : groupLink,
      );

      if (!this.filterLabels.length) return url;

      return mergeUrlParams({ label_name: this.filterLabels }, url, { spreadArrays: true });
    },
    popoverTarget() {
      return `${this.requestPath}__${this.identifier}`.replace('/', '_');
    },
    hasRequestPath() {
      return Boolean(this.requestPath.length);
    },
  },
  methods: {
    drillDownClicked() {
      if (this.trackingProperty === '') return;

      this.trackEvent(EVENT_LABEL_CLICK_METRIC_IN_DASHBOARD_TABLE, {
        label: this.identifier,
        property: this.trackingProperty,
      });
    },
  },
  i18n: {
    docsLabel: s__('DORA4Metrics|Learn more'),
  },
};
</script>
<template>
  <div>
    <gl-link
      v-if="hasRequestPath"
      :href="link"
      data-testid="metric_label"
      variant="meta"
      @click="drillDownClicked"
      >{{ metric.label }}</gl-link
    >
    <span v-else data-testid="metric_label">{{ metric.label }}</span>
    <gl-icon
      :id="popoverTarget"
      data-testid="info_icon"
      name="information-o"
      class="gl-text-blue-600"
    />
    <gl-popover :target="popoverTarget" :title="metric.label" show-close-button>
      {{ tooltip.description }}
      <gl-link :href="tooltip.docsLink" class="gl-mt-2 gl-block gl-text-sm" target="_blank">
        {{ $options.i18n.docsLabel }}
        <gl-icon name="external-link" class="gl-align-middle" />
      </gl-link>
    </gl-popover>
  </div>
</template>
