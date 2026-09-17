<script>
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import {
  ACCESSIBILITY_ROUTE,
  CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';
import { InternalEvents } from '~/tracking';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { EXTENSION_ICONS } from '../../constants';
import {
  accessibilityErrorCount,
  accessibilitySummaryText,
  accessibilityWidgetItems,
} from './utils';

export default {
  name: 'WidgetAccessibility',
  i18n: {
    loading: s__('Reports|Accessibility scanning results are being parsed'),
    error: s__('Reports|Accessibility scanning failed loading results'),
  },
  components: {
    MrWidget,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  emits: ['loaded'],
  data() {
    return {
      collapsedData: {},
      statusMessage: '',
    };
  },
  computed: {
    content() {
      return accessibilityWidgetItems(this.collapsedData);
    },
    numberOfErrors() {
      return accessibilityErrorCount(this.collapsedData);
    },
    statusIcon() {
      if (this.statusMessage || this.collapsedData?.status === 'failed') {
        return EXTENSION_ICONS.warning;
      }

      return EXTENSION_ICONS.success;
    },
    summary() {
      return { title: this.statusMessage || accessibilitySummaryText(this.numberOfErrors) };
    },
    shouldCollapse() {
      return this.numberOfErrors > 0;
    },
    hasReportsTab() {
      return Boolean(this.mr.reportsTabPath);
    },
    actionButtons() {
      if (!this.hasReportsTab) {
        return [];
      }

      return [
        {
          text: s__('MrReports|View report'),
          href: joinPaths(this.mr.reportsTabPath, ACCESSIBILITY_ROUTE),
          onClick: (action, e) => {
            e.preventDefault();
            this.trackEvent(CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET, {
              label: TRACKING_LABEL_BY_ROUTE[ACCESSIBILITY_ROUTE],
            });
            window.history.pushState(null, null, action.href);
            window.dispatchEvent(new PopStateEvent('popstate'));
          },
        },
      ];
    },
  },
  methods: {
    fetchCollapsedData() {
      return axios.get(this.mr.accessibilityReportPath).then((response) => {
        if (response.data) {
          this.collapsedData = response.data;
          this.$emit('loaded', this.numberOfErrors);
        } else if (!normalizeHeaders(response.headers)['POLL-INTERVAL']) {
          this.statusMessage = s__('Reports|Accessibility scanning results are not available');
        }

        return response;
      });
    },
  },
};
</script>
<template>
  <mr-widget
    :action-buttons="actionButtons"
    :error-text="$options.i18n.error"
    :status-icon-name="statusIcon"
    :loading-text="$options.i18n.loading"
    :widget-name="$options.name"
    :summary="summary"
    :content="content"
    :is-collapsible="hasReportsTab ? false : shouldCollapse"
    :expand-button-label="s__('AccessibilityReport|Expand accessibility details')"
    :collapse-button-label="s__('AccessibilityReport|Collapse accessibility details')"
    :fetch-collapsed-data="fetchCollapsedData"
  />
</template>
