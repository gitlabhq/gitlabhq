import IssueStatusIcon from '~/ci/reports/components/issue_status_icon.vue';

export const components = {
  CodequalityIssueBody: () => import('../codequality_report/components/codequality_issue_body.vue'),
};

export const componentNames = {
  CodequalityIssueBody: 'CodequalityIssueBody',
};

export const iconComponents = {
  IssueStatusIcon,
};

export const iconComponentNames = {
  IssueStatusIcon: IssueStatusIcon.name,
};
