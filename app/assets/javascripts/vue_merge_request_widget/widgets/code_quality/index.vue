<script>
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { SEVERITY_ICONS_MR_WIDGET } from '~/ci/reports/codequality_report/constants';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import axios from '~/lib/utils/axios_utils';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { i18n, codeQualityPrefixes } from './constants';

const translations = i18n;

export default {
  name: 'WidgetCodeQuality',
  components: {
    MrWidget,
  },
  i18n: translations,
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
      poll: null,
    };
  },
  computed: {
    summary() {
      const { new_errors, resolved_errors } = this.collapsedData;

      if (!this.pollingFinished) {
        return { title: i18n.loading };
      }
      if (this.hasError) {
        return { title: i18n.error };
      }
      if (
        this.collapsedData?.new_errors?.length >= 1 &&
        this.collapsedData?.resolved_errors?.length >= 1
      ) {
        return {
          title: i18n.improvementAndDegradationCopy(
            i18n.findings(resolved_errors, codeQualityPrefixes.fixed),
            i18n.findings(new_errors, codeQualityPrefixes.new),
          ),
        };
      }
      if (this.collapsedData?.resolved_errors?.length >= 1) {
        return {
          title: i18n.singularCopy(i18n.findings(resolved_errors, codeQualityPrefixes.fixed)),
        };
      }
      if (this.collapsedData?.new_errors?.length >= 1) {
        return { title: i18n.singularCopy(i18n.findings(new_errors, codeQualityPrefixes.new)) };
      }
      return { title: i18n.noChanges };
    },
    expandedData() {
      const fullData = [];
      this.collapsedData?.new_errors?.forEach((e) => {
        fullData.push({
          text: e.check_name
            ? `${capitalizeFirstCharacter(e.severity)} - ${e.check_name} - ${e.description}`
            : `${capitalizeFirstCharacter(e.severity)} - ${e.description}`,
          link: {
            href: e.web_url,
            text: `${i18n.prependText} ${e.file_path}:${e.line}`,
          },
          icon: {
            name: SEVERITY_ICONS_MR_WIDGET[e.severity],
          },
        });
      });

      this.collapsedData?.resolved_errors?.forEach((e) => {
        fullData.push({
          text: e.check_name
            ? `${capitalizeFirstCharacter(e.severity)} - ${e.check_name} - ${e.description}`
            : `${capitalizeFirstCharacter(e.severity)} - ${e.description}`,
          supportingText: `${i18n.prependText} ${e.file_path}:${e.line}`,
          icon: {
            name: SEVERITY_ICONS_MR_WIDGET[e.severity],
          },
          badge: {
            variant: 'neutral',
            text: i18n.fixed,
          },
        });
      });

      return fullData;
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
    :fetch-collapsed-data="fetchCodeQuality"
    :error-text="$options.i18n.error"
    :has-error="hasError"
    :content="expandedData"
    :loading-text="$options.i18n.loading"
    :summary="summary"
    :widget-name="$options.name"
    :status-icon-name="statusIcon"
    :is-collapsible="shouldCollapse"
  />
</template>
