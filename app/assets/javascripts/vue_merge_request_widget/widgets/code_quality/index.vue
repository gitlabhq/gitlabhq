<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { s__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import {
  CODE_QUALITY_ROUTE,
  CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';
import { InternalEvents } from '~/tracking';
import axios from '~/lib/utils/axios_utils';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { i18n } from './constants';
import {
  codeQualitySummary,
  transformNewCodeQualityFinding,
  transformResolvedCodeQualityFinding,
} from './utils';

export default {
  name: 'WidgetCodeQuality',
  components: {
    MrWidget,
  },
  mixins: [InternalEvents.mixin(), glFeatureFlagsMixin()],
  i18n,
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      pollingFinished: false,
      hasError: false,
      collapsedData: {},
    };
  },
  computed: {
    summary() {
      if (!this.pollingFinished) {
        return { title: i18n.loading };
      }
      if (this.hasError) {
        return { title: i18n.error };
      }
      return {
        title: codeQualitySummary({
          newCount: this.collapsedData?.new_errors?.length || 0,
          resolvedCount: this.collapsedData?.resolved_errors?.length || 0,
        }),
      };
    },
    expandedData() {
      return [
        ...(this.collapsedData?.new_errors?.map(transformNewCodeQualityFinding) || []),
        ...(this.collapsedData?.resolved_errors?.map(transformResolvedCodeQualityFinding) || []),
      ];
    },
    statusIcon() {
      if (this.collapsedData?.new_errors?.length >= 1) {
        return EXTENSION_ICONS.warning;
      }
      if (this.collapsedData?.resolved_errors?.length >= 1) {
        return EXTENSION_ICONS.success;
      }
      return EXTENSION_ICONS.neutral;
    },
    shouldCollapse() {
      const { new_errors: newErrors, resolved_errors: resolvedErrors } = this.collapsedData;

      if ((newErrors?.length === 0 && resolvedErrors?.length === 0) || this.hasError) {
        return false;
      }
      return true;
    },
    hasReportsTab() {
      return this.glFeatures.mrReportsTab && Boolean(this.mr.reportsTabPath);
    },
    actionButtons() {
      if (this.hasReportsTab) {
        return [
          {
            text: s__('MrReports|View report'),
            href: joinPaths(this.mr.reportsTabPath, CODE_QUALITY_ROUTE),
            onClick: (action, e) => {
              e.preventDefault();
              this.trackEvent(CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET, {
                label: TRACKING_LABEL_BY_ROUTE[CODE_QUALITY_ROUTE],
              });
              window.history.pushState(null, null, action.href);
              window.dispatchEvent(new PopStateEvent('popstate'));
            },
          },
        ];
      }
      return [];
    },
    apiCodeQualityPath() {
      return this.mr.codequalityReportsPath;
    },
  },
  methods: {
    setCollapsedError(err) {
      this.hasError = true;

      Sentry.captureException(err);
    },
    fetchCodeQuality() {
      return axios
        .get(this.apiCodeQualityPath)
        .then(({ data, headers = {}, status }) => {
          if (status === HTTP_STATUS_OK) {
            this.pollingFinished = true;
          }
          if (data) {
            this.collapsedData = data;
            this.$emit('loaded', this.collapsedData.new_errors.length);
          }
          return {
            headers,
            status,
            data,
          };
        })
        .catch((e) => {
          return this.setCollapsedError(e);
        });
    },
  },
};
</script>

<template>
  <mr-widget
    :action-buttons="actionButtons"
    :fetch-collapsed-data="fetchCodeQuality"
    :error-text="$options.i18n.error"
    :has-error="hasError"
    :content="expandedData"
    :loading-text="$options.i18n.loading"
    :summary="summary"
    :widget-name="$options.name"
    :status-icon-name="statusIcon"
    :is-collapsible="hasReportsTab ? false : shouldCollapse"
    :expand-button-label="s__('ciReport|Expand Code Quality details')"
    :collapse-button-label="s__('ciReport|Collapse Code Quality details')"
  />
</template>
