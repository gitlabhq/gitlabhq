<script>
import { __, n__, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { EXTENSION_ICONS } from '../../constants';

export default {
  name: 'WidgetTerraform',
  components: {
    MrWidget,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      terraformData: {
        collapsed: null,
        expanded: null,
      },
    };
  },
  i18n: {
    loading: s__('Terraform|Loading Terraform reports…'),
    error: s__('Terraform|Failed to load Terraform reports'),
    reportGenerated: s__('Terraform|A Terraform report was generated in your pipelines.'),
    namedReportGenerated: s__(
      'Terraform|The job %{strong_start}%{name}%{strong_end} generated a report.',
    ),
    reportChanges: s__(
      'Terraform|Reported Resource Changes: %{addNum} to add, %{changeNum} to change, %{deleteNum} to delete',
    ),
    reportFailed: s__('Terraform|A Terraform report failed to generate.'),
    namedReportFailed: s__(
      'Terraform|The job %{strong_start}%{name}%{strong_end} failed to generate a report.',
    ),
    reportErrored: s__('Terraform|Generating the report caused an error.'),
    fullLog: __('Full log'),
  },
  computed: {
    terraformReportsPath() {
      return this.mr.terraformReportsPath;
    },

    summary() {
      const { valid = [], invalid = [] } = this.terraformData.collapsed || {};

      const validText = sprintf(
        n__(
          'Terraform|%{strong_start}%{number}%{strong_end} Terraform report was generated in your pipelines',
          'Terraform|%{strong_start}%{number}%{strong_end} Terraform reports were generated in your pipelines',
          valid.length,
        ),
        {
          number: valid.length,
        },
        false,
      );

      const invalidText = sprintf(
        n__(
          'Terraform|%{strong_start}%{number}%{strong_end} Terraform report failed to generate',
          'Terraform|%{strong_start}%{number}%{strong_end} Terraform reports failed to generate',
          invalid.length,
        ),
        {
          number: invalid.length,
        },
        false,
      );

      return {
        title: valid.length ? validText : invalidText,
        subtitle: valid.length && invalid.length ? invalidText : undefined,
      };
    },
  },
  methods: {
    fetchCollapsedData() {
      return axios
        .get(this.terraformReportsPath)
        .then((res) => {
          const reports = Object.keys(res.data).map((key) => {
            const report = res.data[key];

            const isValid =
              report.create + report.update + report.delete >= 0 && !report.tf_report_error;
            const sortIndex = Number(report.create) + Number(report.update) + Number(report.delete);

            return {
              ...report,
              isValid,
              sortIndex,
            };
          });

          // Higher "sortIndex" means earlier in the list, therefore
          // higher in the UI
          reports.sort((a, b) => b.sortIndex - a.sortIndex);

          const formattedData = this.prepareReports(reports);

          const { valid, invalid } = formattedData;
          this.terraformData.collapsed = formattedData;
          this.terraformData.expanded = [...valid, ...invalid];

          this.$emit('loaded', this.terraformData.collapsed.invalid.length);

          return {
            ...res,
            data: formattedData,
          };
        })
        .catch(() => {
          const formattedData = this.prepareReports([{ tf_report_error: 'api_error' }]);
          this.terraformData.collapsed = formattedData;
          return { data: formattedData };
        });
    },
    createReportRow(report, iconName) {
      const actions = [];

      let title;
      let subtitle;

      if (report.job_path) {
        const action = {
          href: report.job_path,
          text: this.$options.i18n.fullLog,
          target: '_blank',
          trackFullReportClicked: true,
        };
        actions.push(action);
      }

      if (report.isValid) {
        if (report.job_name) {
          title = sprintf(
            this.$options.i18n.namedReportGenerated,
            {
              name: report.job_name,
            },
            false,
          );
        } else {
          title = this.$options.i18n.reportGenerated;
        }

        subtitle = sprintf(`%{small_start}${this.$options.i18n.reportChanges}%{small_end}`, {
          addNum: report.create,
          changeNum: report.update,
          deleteNum: report.delete,
        });
      } else {
        if (report.job_name) {
          title = sprintf(
            this.$options.i18n.namedReportFailed,
            {
              name: report.job_name,
            },
            false,
          );
        } else {
          title = this.$options.i18n.reportFailed;
        }

        subtitle = sprintf(`%{small_start}${this.$options.i18n.reportErrored}%{small_end}`);
      }

      return {
        text: title,
        supportingText: subtitle,
        icon: { name: iconName },
        actions,
      };
    },
    prepareReports(reports) {
      const valid = [];
      const invalid = [];

      reports.forEach((report) => {
        if (report.isValid) {
          valid.push(this.createReportRow(report, EXTENSION_ICONS.success));
        } else {
          invalid.push(this.createReportRow(report, EXTENSION_ICONS.error));
        }
      });

      return { valid, invalid };
    },
  },

  WARNING_ICON: EXTENSION_ICONS.warning,
};
</script>

<template>
  <mr-widget
    :error-text="$options.i18n.error"
    :status-icon-name="$options.WARNING_ICON"
    :loading-text="$options.i18n.loading"
    :widget-name="$options.name"
    :is-collapsible="Boolean(terraformData.collapsed)"
    :summary="summary"
    :content="terraformData.expanded"
    :fetch-collapsed-data="fetchCollapsedData"
    :label="__('Terraform')"
    path="terraform"
  />
</template>
