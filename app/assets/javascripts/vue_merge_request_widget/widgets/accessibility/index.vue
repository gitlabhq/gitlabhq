<script>
import { uniqueId } from 'lodash';
import { __, n__, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { EXTENSION_ICONS } from '../../constants';

export default {
  name: 'WidgetAccessibility',
  i18n: {
    loading: s__('Reports|Accessibility scanning results are being parsed'),
    error: s__('Reports|Accessibility scanning failed loading results'),
    newErrorsHeader: __('New'),
    existingErrorsHeader: __('Not fixed'),
    resolvedErrorsHeader: __('Fixed'),
  },
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
      collapsedData: {},
      content: [],
    };
  },
  computed: {
    statusIcon() {
      return this.collapsedData?.status === 'failed'
        ? EXTENSION_ICONS.warning
        : EXTENSION_ICONS.success;
    },
    summary() {
      const numOfResults = this.collapsedData?.summary?.errored || 0;

      const successText = s__(
        'Reports|Accessibility scanning detected no issues for the source branch only',
      );
      const warningText = sprintf(
        n__(
          'Reports|Accessibility scanning detected %{strong_start}%{number}%{strong_end} issue for the source branch only',
          'Reports|Accessibility scanning detected %{strong_start}%{number}%{strong_end} issues for the source branch only',
          numOfResults,
        ),
        {
          number: numOfResults,
        },
        false,
      );

      return numOfResults === 0 ? { title: successText } : { title: warningText };
    },
    shouldCollapse() {
      return this.collapsedData?.summary?.errored > 0;
    },
  },
  methods: {
    fetchCollapsedData() {
      return axios.get(this.mr.accessibilityReportPath).then((response) => {
        this.collapsedData = response.data;
        this.content = this.getContent(response.data);
        this.$emit('loaded', this.collapsedData?.summary?.errored || 0);

        return response;
      });
    },
    fetchFullData() {
      return Promise.resolve(this.prepareReports());
    },
    parsedTECHSCode(code) {
      /*
       * In issue code looks like "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail"
       * or "WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent"
       *
       * The TECHS code is the "G18", "G168", "H91", etc. from the code which is used for the documentation.
       * Here we simply split the string on `.` and get the code in the 5th position
       */
      return code?.split('.')[4];
    },
    formatLearnMoreUrl(code) {
      const parsed = this.parsedTECHSCode(code);
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `https://www.w3.org/TR/WCAG20-TECHS/${parsed || 'Overview'}.html`;
    },
    formatText(code) {
      return sprintf(
        s__(
          'AccessibilityReport|The accessibility scanning found an error of the following type: %{code}',
        ),
        { code },
      );
    },
    formatMessage(message) {
      return sprintf(s__('AccessibilityReport|Message: %{message}'), { message });
    },
    getContent(collapsedData) {
      const newErrors = collapsedData.new_errors.map((error, i) => {
        return {
          header: i === 0 ? this.$options.i18n.newErrorsHeader : '',
          id: uniqueId('new-error-'),
          text: this.formatText(error.code),
          icon: { name: EXTENSION_ICONS.failed },
          supportingText: this.formatMessage(error.message),
          actions: [
            {
              id: uniqueId('new-error-details-link-'),
              text: __('Details'),
              icon: 'external-link',
              href: this.formatLearnMoreUrl(error.code),
              variant: 'link',
            },
          ],
        };
      });

      const existingErrors = collapsedData.existing_errors.map((error, i) => {
        return {
          header: i === 0 ? this.$options.i18n.existingErrorsHeader : '',
          id: uniqueId('existing-error-'),
          text: this.formatText(error.code),
          icon: { name: EXTENSION_ICONS.failed },
          supportingText: this.formatMessage(error.message),
          actions: [
            {
              id: uniqueId('existing-error-details-link-'),
              text: __('Details'),
              icon: 'external-link',
              href: this.formatLearnMoreUrl(error.code),
              variant: 'link',
            },
          ],
        };
      });

      const resolvedErrors = collapsedData.resolved_errors.map((error, i) => {
        return {
          header: i === 0 ? this.$options.i18n.resolvedErrorsHeader : '',
          id: uniqueId('resolved-error-'),
          text: this.formatText(error.code),
          icon: { name: EXTENSION_ICONS.success },
          supportingText: this.formatMessage(error.message),
          actions: [
            {
              id: uniqueId('resolved-error-details-link-'),
              text: __('Details'),
              icon: 'external-link',
              href: this.formatLearnMoreUrl(error.code),
              variant: 'link',
            },
          ],
        };
      });

      return [...newErrors, ...existingErrors, ...resolvedErrors];
    },
  },
};
</script>
<template>
  <mr-widget
    :error-text="$options.i18n.error"
    :status-icon-name="statusIcon"
    :loading-text="$options.i18n.loading"
    :widget-name="$options.name"
    :summary="summary"
    :content="content"
    :is-collapsible="shouldCollapse"
    :fetch-collapsed-data="fetchCollapsedData"
  />
</template>
