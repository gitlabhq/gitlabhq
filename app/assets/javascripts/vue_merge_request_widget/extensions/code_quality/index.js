import axios from '~/lib/utils/axios_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { SEVERITY_ICONS_MR_WIDGET } from '~/ci/reports/codequality_report/constants';
import { HTTP_STATUS_NO_CONTENT } from '~/lib/utils/http_status';
import { parseCodeclimateMetrics } from '~/ci/reports/codequality_report/store/utils/codequality_parser';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { i18n } from './constants';

export default {
  name: 'WidgetCodeQuality',
  enablePolling: true,
  props: ['codeQuality', 'blobPath'],
  i18n,
  computed: {
    summary(data) {
      const { newErrors, resolvedErrors, errorSummary, parsingInProgress } = data;

      if (parsingInProgress) {
        return i18n.loading;
      } else if (errorSummary.errored >= 1 && errorSummary.resolved >= 1) {
        return i18n.improvementAndDegradationCopy(
          i18n.pluralReport(resolvedErrors),
          i18n.pluralReport(newErrors),
        );
      } else if (errorSummary.resolved >= 1) {
        return i18n.improvedCopy(i18n.singularReport(resolvedErrors));
      } else if (errorSummary.errored >= 1) {
        return i18n.degradedCopy(i18n.singularReport(newErrors));
      }
      return i18n.noChanges;
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
      return axios.get(this.codeQuality).then((response) => {
        const { data = {}, status } = response;
        return {
          ...response,
          data: {
            parsingInProgress: status === HTTP_STATUS_NO_CONTENT,
            resolvedErrors: parseCodeclimateMetrics(data.resolved_errors, this.blobPath.head_path),
            newErrors: parseCodeclimateMetrics(data.new_errors, this.blobPath.head_path),
            existingErrors: parseCodeclimateMetrics(data.existing_errors, this.blobPath.head_path),
            errorSummary: data.summary,
          },
        };
      });
    },
    fetchFullData() {
      const fullData = [];

      this.collapsedData.newErrors.map((e) => {
        return fullData.push({
          text: `${capitalizeFirstCharacter(e.severity)} - ${e.description}`,
          subtext: {
            prependText: i18n.prependText,
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
            prependText: i18n.prependText,
            text: `${e.file_path}:${e.line}`,
            href: e.urlPath,
          },
          icon: {
            name: SEVERITY_ICONS_MR_WIDGET[e.severity],
          },
          badge: {
            variant: 'neutral',
            text: i18n.fixed,
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
