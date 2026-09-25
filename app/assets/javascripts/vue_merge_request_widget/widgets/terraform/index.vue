<script>
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import {
  TERRAFORM_ROUTE,
  CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET,
  TRACKING_LABEL_BY_ROUTE,
} from '~/merge_requests/reports/constants';
import { InternalEvents } from '~/tracking';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { EXTENSION_ICONS } from '../../constants';
import { terraformInvalidCount, terraformRows, terraformSummary } from './utils';

export default {
  name: 'WidgetTerraform',
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
      collapsedData: null,
    };
  },
  i18n: {
    loading: s__('Terraform|Loading Terraform reports…'),
    error: s__('Terraform|Failed to load Terraform reports'),
  },
  computed: {
    terraformReportsPath() {
      return this.mr.terraformReportsPath;
    },
    content() {
      return terraformRows(this.collapsedData);
    },
    summary() {
      return terraformSummary(this.collapsedData);
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
          href: joinPaths(this.mr.reportsTabPath, TERRAFORM_ROUTE),
          onClick: (action, e) => {
            e.preventDefault();
            this.trackEvent(CLICK_VIEW_REPORT_ON_MERGE_REQUEST_WIDGET, {
              label: TRACKING_LABEL_BY_ROUTE[TERRAFORM_ROUTE],
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
      return axios
        .get(this.terraformReportsPath)
        .then((res) => {
          this.collapsedData = res.data;
          this.$emit('loaded', terraformInvalidCount(res.data));

          return res;
        })
        .catch(() => {
          this.collapsedData = { api_error: { tf_report_error: 'api_error' } };

          return { data: this.collapsedData };
        });
    },
  },

  WARNING_ICON: EXTENSION_ICONS.warning,
};
</script>

<template>
  <mr-widget
    :action-buttons="actionButtons"
    :error-text="$options.i18n.error"
    :status-icon-name="$options.WARNING_ICON"
    :loading-text="$options.i18n.loading"
    :widget-name="$options.name"
    :is-collapsible="hasReportsTab ? false : Boolean(collapsedData)"
    :expand-button-label="s__('Terraform|Expand Terraform report details')"
    :collapse-button-label="s__('Terraform|Collapse Terraform report details')"
    :summary="summary"
    :content="content"
    :fetch-collapsed-data="fetchCollapsedData"
  />
</template>
