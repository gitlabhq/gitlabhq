/**
 * Context:
 *   https://gitlab.com/gitlab-org/gitlab/-/issues/198524
 *   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29491
 *
 */

/**
 * Constants
 *
 * LABEL_NAMES - an array of labels to filter issues in the GraphQL query
 * WORKFLOW_PREFIX - the prefix for workflow labels
 * ACCEPTING_CONTRIBUTIONS_TITLE - the accepting contributions label
 */
export const LABEL_NAMES = ['Package::Coming soon'];
const WORKFLOW_PREFIX = 'workflow::';
const ACCEPTING_CONTRIBUTIONS_TITLE = 'accepting merge requests';

const setScoped = (label, scoped) => (label ? { ...label, scoped } : label);

/**
 * Finds workflow:: scoped labels and returns the first or null.
 * @param {Object[]} labels Labels from the issue
 */
export const findWorkflowLabel = (labels = []) =>
  labels.find(l => l.title.toLowerCase().includes(WORKFLOW_PREFIX.toLowerCase()));

/**
 * Determines if an issue is accepting community contributions by checking if
 * the "Accepting merge requests" label is present.
 * @param {Object[]} labels
 */
export const findAcceptingContributionsLabel = (labels = []) =>
  labels.find(l => l.title.toLowerCase() === ACCEPTING_CONTRIBUTIONS_TITLE.toLowerCase());

/**
 * Formats the GraphQL response into the format that the view template expects.
 * @param {Object} data GraphQL response
 */
export const toViewModel = data => {
  // This just flatterns the issues -> nodes and labels -> nodes hierarchy
  // into an array of objects.
  const issues = (data.project?.issues?.nodes || []).map(i => ({
    ...i,
    labels: (i.labels?.nodes || []).map(node => node),
  }));

  return issues.map(x => ({
    ...x,
    labels: [
      setScoped(findWorkflowLabel(x.labels), true),
      setScoped(findAcceptingContributionsLabel(x.labels), false),
    ].filter(Boolean),
  }));
};
