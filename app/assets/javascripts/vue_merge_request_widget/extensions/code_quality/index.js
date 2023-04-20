import axios from '~/lib/utils/axios_utils';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { SEVERITY_ICONS_MR_WIDGET } from '~/ci/reports/codequality_report/constants';
import { HTTP_STATUS_NO_CONTENT } from '~/lib/utils/http_status';
import { parseCodeclimateMetrics } from '~/ci/reports/codequality_report/store/utils/codequality_parser';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { i18n, codeQualityPrefixes } from './constants';

export default {
  name: 'WidgetCodeQuality',
  enablePolling: true,
  props: ['codeQuality', 'blobPath'],
  i18n,
  computed: {
    shouldCollapse(data) {
      const { newErrors, resolvedErrors, parsingInProgress } = data;
      if (parsingInProgress || (newErrors.length === 0 && resolvedErrors.length === 0)) {
        return false;
      }
      return true;
    },
    summary(data) {
      const { newErrors, resolvedErrors, parsingInProgress } = data;
      if (parsingInProgress) {
        return i18n.loading;
      } else if (newErrors.length >= 1 && resolvedErrors.length >= 1) {
        return i18n.improvementAndDegradationCopy(
          i18n.findings(resolvedErrors, codeQualityPrefixes.fixed),
          i18n.findings(newErrors, codeQualityPrefixes.new),
        );
      } else if (resolvedErrors.length >= 1) {
        return i18n.singularCopy(i18n.findings(resolvedErrors, codeQualityPrefixes.fixed));
      } else if (newErrors.length >= 1) {
        return i18n.singularCopy(i18n.findings(newErrors, codeQualityPrefixes.new));
      }
      return i18n.noChanges;
    },
    statusIcon() {
      if (this.collapsedData.newErrors.length >= 1) {
        return EXTENSION_ICONS.warning;
      } else if (this.collapsedData.resolvedErrors.length >= 1) {
        return EXTENSION_ICONS.success;
      }
      return EXTENSION_ICONS.neutral;
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
          },
        };
      });
    },
    fetchFullData() {
      const fullData = [];

      this.collapsedData.newErrors.map((e) => {
        return fullData.push({
          text: e.check_name
            ? `${capitalizeFirstCharacter(e.severity)} - ${e.check_name} - ${e.description}`
            : `${capitalizeFirstCharacter(e.severity)} - ${e.description}`,
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
          text: e.check_name
            ? `${capitalizeFirstCharacter(e.severity)} - ${e.check_name} - ${e.description}`
            : `${capitalizeFirstCharacter(e.severity)} - ${e.description}`,
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
