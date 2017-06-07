const stateToComponentMap = {
  merged: 'mr-widget-merged',
  closed: 'mr-widget-closed',
  locked: 'mr-widget-locked',
  conflicts: 'mr-widget-conflicts',
  missingBranch: 'mr-widget-missing-branch',
  workInProgress: 'mr-widget-wip',
  readyToMerge: 'mr-widget-ready-to-merge',
  nothingToMerge: 'mr-widget-nothing-to-merge',
  notAllowedToMerge: 'mr-widget-not-allowed',
  archived: 'mr-widget-archived',
  checking: 'mr-widget-checking',
  unresolvedDiscussions: 'mr-widget-unresolved-discussions',
  pipelineBlocked: 'mr-widget-pipeline-blocked',
  pipelineFailed: 'mr-widget-pipeline-failed',
  mergeWhenPipelineSucceeds: 'mr-widget-merge-when-pipeline-succeeds',
  failedToMerge: 'mr-widget-failed-to-merge',
  autoMergeFailed: 'mr-widget-auto-merge-failed',
  shaMismatch: 'mr-widget-sha-mismatch',
};

const statesToShowHelpWidget = [
  'locked',
  'conflicts',
  'workInProgress',
  'readyToMerge',
  'checking',
  'unresolvedDiscussions',
  'pipelineFailed',
  'pipelineBlocked',
  'autoMergeFailed',
];

export default {
  stateToComponentMap,
  statesToShowHelpWidget,
};
