import { uniqueId } from 'lodash';
import { __, n__, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { EXTENSION_ICONS } from '../../constants';

export default {
  name: 'WidgetAccessibility',
  enablePolling: true,
  i18n: {
    loading: s__('Reports|Accessibility scanning results are being parsed'),
    error: s__('Reports|Accessibility scanning failed loading results'),
  },
  props: ['accessibilityReportPath'],
  computed: {
    statusIcon() {
      return this.collapsedData.status === 'failed'
        ? EXTENSION_ICONS.warning
        : EXTENSION_ICONS.success;
    },
  },
  methods: {
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

      return numOfResults === 0 ? successText : warningText;
    },
    shouldCollapse() {
      return this.collapsedData?.summary?.errored > 0;
    },
    fetchCollapsedData() {
      return axios.get(this.accessibilityReportPath);
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
    prepareReports() {
      const { collapsedData } = this;

      const newErrors = collapsedData.new_errors.map((error) => {
        return {
          header: __('New'),
          id: uniqueId('new-error-'),
          text: this.formatText(error.code),
          icon: { name: EXTENSION_ICONS.failed },
          link: {
            href: this.formatLearnMoreUrl(error.code),
            text: __('Learn more'),
          },
          supportingText: this.formatMessage(error.message),
        };
      });

      const existingErrors = collapsedData.existing_errors.map((error) => {
        return {
          id: uniqueId('existing-error-'),
          text: this.formatText(error.code),
          icon: { name: EXTENSION_ICONS.failed },
          link: {
            href: this.formatLearnMoreUrl(error.code),
            text: __('Learn more'),
          },
          supportingText: this.formatMessage(error.message),
        };
      });

      const resolvedErrors = collapsedData.resolved_errors.map((error) => {
        return {
          id: uniqueId('resolved-error-'),
          text: this.formatText(error.code),
          icon: { name: EXTENSION_ICONS.success },
          link: {
            href: this.formatLearnMoreUrl(error.code),
            text: __('Learn more'),
          },
          supportingText: this.formatMessage(error.message),
        };
      });

      return [...newErrors, ...existingErrors, ...resolvedErrors];
    },
  },
};
