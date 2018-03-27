const stateToComponentMap = {
  merged: 'mr-widget-merged',
  closed: 'mr-widget-closed',
  merging: 'mr-widget-merging',
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
  shaMismatch: 'sha-mismatch',
  rebase: 'mr-widget-rebase',
};

const statesToShowHelpWidget = [
  'merging',
  'conflicts',
  'workInProgress',
  'readyToMerge',
  'checking',
  'unresolvedDiscussions',
  'pipelineFailed',
  'pipelineBlocked',
  'autoMergeFailed',
  'rebase',
];

export const stateKey = {
  archived: 'archived',
  missingBranch: 'missingBranch',
  nothingToMerge: 'nothingToMerge',
  checking: 'checking',
  conflicts: 'conflicts',
  workInProgress: 'workInProgress',
  pipelineFailed: 'pipelineFailed',
  unresolvedDiscussions: 'unresolvedDiscussions',
  pipelineBlocked: 'pipelineBlocked',
  shaMismatch: 'shaMismatch',
  autoMergeFailed: 'autoMergeFailed',
  mergeWhenPipelineSucceeds: 'mergeWhenPipelineSucceeds',
  notAllowedToMerge: 'notAllowedToMerge',
  readyToMerge: 'readyToMerge',
  rebase: 'rebase',
  merged: 'merged',
};

export default {
  stateToComponentMap,
  statesToShowHelpWidget,
};
