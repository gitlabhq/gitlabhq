import { n__, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { SEVERITY_ICONS_MR_WIDGET } from '~/ci/reports/codequality_report/constants';
import { parseCodeclimateMetrics } from '~/ci/reports/codequality_report/store/utils/codequality_parser';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export default {
  name: 'WidgetCodeQuality',
  props: ['codeQuality', 'blobPath'],
  i18n: {
    label: s__('ciReport|Code Quality'),
    loading: s__('ciReport|Code Quality test metrics results are being parsed'),
    error: s__('ciReport|Code Quality failed loading results'),
  },
  computed: {
    summary() {
      const { newErrors, resolvedErrors, errorSummary } = this.collapsedData;
      if (errorSummary.errored >= 1 && errorSummary.resolved >= 1) {
        const improvements = sprintf(
          n__(
            '%{strong_start}%{errors}%{strong_end} point',
            '%{strong_start}%{errors}%{strong_end} points',
            resolvedErrors.length,
          ),
          {
            errors: resolvedErrors.length,
          },
          false,
        );

        const degradations = sprintf(
          n__(
            '%{strong_start}%{errors}%{strong_end} point',
            '%{strong_start}%{errors}%{strong_end} points',
            newErrors.length,
          ),
          { errors: newErrors.length },
          false,
        );
        return sprintf(
          s__(`ciReport|Code Quality improved on ${improvements} and degraded on ${degradations}.`),
        );
      } else if (errorSummary.resolved >= 1) {
        const improvements = n__('%d point', '%d points', resolvedErrors.length);
        return sprintf(s__(`ciReport|Code Quality improved on ${improvements}.`));
      } else if (errorSummary.errored >= 1) {
        const degradations = n__('%d point', '%d points', newErrors.length);
        return sprintf(s__(`ciReport|Code Quality degraded on ${degradations}.`));
      }
      return s__(`ciReport|No changes to Code Quality.`);
    },
    statusIcon() {
      if (this.collapsedData.errorSummary?.errored >= 1) {
        return EXTENSION_ICONS.warning;
      }
      return EXTENSION_ICONS.success;
    },
  },
  methods: {
    fetchCollapsedData() {
      return Promise.all([this.fetchReport(this.codeQuality)]).then((values) => {
        return {
          resolvedErrors: parseCodeclimateMetrics(
            values[0].resolved_errors,
            this.blobPath.head_path,
          ),
          newErrors: parseCodeclimateMetrics(values[0].new_errors, this.blobPath.head_path),
          existingErrors: parseCodeclimateMetrics(
            values[0].existing_errors,
            this.blobPath.head_path,
          ),
          errorSummary: values[0].summary,
        };
      });
    },
    fetchFullData() {
      const fullData = [];

      this.collapsedData.newErrors.map((e) => {
        return fullData.push({
          text: `${capitalizeFirstCharacter(e.severity)} - ${e.description}`,
          subtext: {
            prependText: s__(`ciReport|in`),
            text: `${e.file_path}:${e.line}`,
            href: e.urlPath,
          },
          icon: {
            name: SEVERITY_ICONS_MR_WIDGET[e.severity],
          },
        });
      });

      this.collapsedData.resolvedErrors.map((e) => {
        return fullData.push({
          text: `${capitalizeFirstCharacter(e.severity)} - ${e.description}`,
          subtext: {
            prependText: s__(`ciReport|in`),
            text: `${e.file_path}:${e.line}`,
            href: e.urlPath,
          },
          icon: {
            name: SEVERITY_ICONS_MR_WIDGET[e.severity],
          },
          badge: {
            variant: 'neutral',
            text: s__(`ciReport|Fixed`),
          },
        });
      });

      return Promise.resolve(fullData);
    },
    fetchReport(endpoint) {
      return axios.get(endpoint).then((res) => res.data);
    },
  },
};
