<script>
import { GlEmptyState } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export const i18n = {
  noTestsButton: s__('TestReports|Learn more about pipeline test reports'),
  noTestsDescription: s__('TestReports|No test cases were found in the test report.'),
  noTestsTitle: s__('TestReports|There are no tests to display'),
  noReportsButton: s__('TestReports|Learn how to upload pipeline test reports'),
  noReportsDescription: s__(
    'TestReports|You can configure your job to use unit test reports, and GitLab displays a report here and in the related merge request.',
  ),
  noReportsTitle: s__('TestReports|There are no test reports for this pipeline'),
};

export default {
  i18n,
  components: {
    GlEmptyState,
  },
  inject: {
    emptyStateImagePath: {
      default: '',
    },
    hasTestReport: {
      default: false,
    },
  },
  computed: {
    emptyStateText() {
      if (this.hasTestReport) {
        return {
          button: this.$options.i18n.noTestsButton,
          description: this.$options.i18n.noTestsDescription,
          title: this.$options.i18n.noTestsTitle,
        };
      }
      return {
        button: this.$options.i18n.noReportsButton,
        description: this.$options.i18n.noReportsDescription,
        title: this.$options.i18n.noReportsTitle,
      };
    },
    testReportDocPath() {
      return helpPagePath('ci/unit_test_reports');
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="emptyStateText.title"
    :description="emptyStateText.description"
    :svg-path="emptyStateImagePath"
    :primary-button-link="testReportDocPath"
    :primary-button-text="emptyStateText.button"
  />
</template>
