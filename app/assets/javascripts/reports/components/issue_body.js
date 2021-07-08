import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import AccessibilityIssueBody from '../accessibility_report/components/accessibility_issue_body.vue';
import CodequalityIssueBody from '../codequality_report/components/codequality_issue_body.vue';
import TestIssueBody from '../grouped_test_report/components/test_issue_body.vue';

export const components = {
  AccessibilityIssueBody,
  CodequalityIssueBody,
  TestIssueBody,
};

export const componentNames = {
  AccessibilityIssueBody: AccessibilityIssueBody.name,
  CodequalityIssueBody: CodequalityIssueBody.name,
  TestIssueBody: TestIssueBody.name,
};

export const iconComponents = {
  IssueStatusIcon,
};

export const iconComponentNames = {
  IssueStatusIcon: IssueStatusIcon.name,
};
