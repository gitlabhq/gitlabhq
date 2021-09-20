import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';

export const components = {
  AccessibilityIssueBody: () =>
    import('../accessibility_report/components/accessibility_issue_body.vue'),
  CodequalityIssueBody: () => import('../codequality_report/components/codequality_issue_body.vue'),
  TestIssueBody: () => import('../grouped_test_report/components/test_issue_body.vue'),
};

export const componentNames = {
  AccessibilityIssueBody: 'AccessibilityIssueBody',
  CodequalityIssueBody: 'CodequalityIssueBody',
  TestIssueBody: 'TestIssueBody',
};

export const iconComponents = {
  IssueStatusIcon,
};

export const iconComponentNames = {
  IssueStatusIcon: IssueStatusIcon.name,
};
