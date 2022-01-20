import { __, n__, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { EXTENSION_ICONS } from '../../constants';

export default {
  name: 'WidgetTerraform',
  enablePolling: true,
  i18n: {
    label: s__('Terraform|Terraform reports'),
    loading: s__('Terraform|Loading Terraform reports...'),
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
  expandEvent: 'i_testing_terraform_widget_total',
  props: ['terraformReportsPath'],
  computed: {
    // Extension computed props
    statusIcon() {
      return EXTENSION_ICONS.warning;
    },
  },
  methods: {
    // Extension methods
    summary({ valid = [], invalid = [] }) {
      let title;
      let subtitle = '';

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

      if (valid.length) {
        title = validText;
        if (invalid.length) {
          subtitle = sprintf(`<br>%{small_start}${invalidText}%{small_end}`);
        }
      } else {
        title = invalidText;
      }

      return `${title}${subtitle}`;
    },
    fetchCollapsedData() {
      return Promise.resolve(this.fetchPlans().then(this.prepareReports));
    },
    fetchFullData() {
      const { valid, invalid } = this.collapsedData;
      return Promise.resolve([...valid, ...invalid]);
    },
    // Custom methods
    fetchPlans() {
      return axios
        .get(this.terraformReportsPath)
        .then(({ data }) => {
          return Object.keys(data).map((key) => {
            return data[key];
          });
        })
        .catch(() => {
          const invalidData = { tf_report_error: 'api_error' };
          return [invalidData];
        });
    },
    createReportRow(report, iconName) {
      const addNum = Number(report.create);
      const changeNum = Number(report.update);
      const deleteNum = Number(report.delete);
      const validPlanValues = addNum + changeNum + deleteNum >= 0;

      const actions = [];

      let title;
      let subtitle;

      if (report.job_path) {
        const action = {
          href: report.job_path,
          text: this.$options.i18n.fullLog,
          target: '_blank',
        };
        actions.push(action);
      }

      if (validPlanValues) {
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
          addNum,
          changeNum,
          deleteNum,
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
        text: `${title}
        <br>
        ${subtitle}`,
        icon: { name: iconName },
        actions,
      };
    },
    prepareReports(reports) {
      const valid = [];
      const invalid = [];

      reports.forEach((report) => {
        if (report.tf_report_error) {
          invalid.push(this.createReportRow(report, EXTENSION_ICONS.error));
        } else {
          valid.push(this.createReportRow(report, EXTENSION_ICONS.success));
        }
      });

      return { valid, invalid };
    },
  },
};
