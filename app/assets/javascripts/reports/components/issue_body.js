import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';

export const components = {
  CodequalityIssueBody: () => import('../codequality_report/components/codequality_issue_body.vue'),
  TestIssueBody: () => import('../grouped_test_report/components/test_issue_body.vue'),
};

export const componentNames = {
  CodequalityIssueBody: 'CodequalityIssueBody',
  TestIssueBody: 'TestIssueBody',
};

export const iconComponents = {
  IssueStatusIcon,
};

export const iconComponentNames = {
  IssueStatusIcon: IssueStatusIcon.name,
};
