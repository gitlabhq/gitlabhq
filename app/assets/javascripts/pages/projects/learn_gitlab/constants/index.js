import { s__ } from '~/locale';

export const ACTION_LABELS = {
  gitWrite: {
    title: s__('LearnGitLab|Create or import a repository'),
    actionLabel: s__('LearnGitLab|Create or import a repository'),
    description: s__('LearnGitLab|Create or import your first repository into your new project.'),
  },
  userAdded: {
    title: s__('LearnGitLab|Invite your colleagues'),
    actionLabel: s__('LearnGitLab|Invite your colleagues'),
    description: s__(
      'LearnGitLab|GitLab works best as a team. Invite your colleague to enjoy all features.',
    ),
  },
  pipelineCreated: {
    title: s__('LearnGitLab|Set up CI/CD'),
    actionLabel: s__('LearnGitLab|Set-up CI/CD'),
    description: s__('LearnGitLab|Save time by automating your integration and deployment tasks.'),
  },
  trialStarted: {
    title: s__('LearnGitLab|Start a free Ultimate trial'),
    actionLabel: s__('LearnGitLab|Try GitLab Ultimate for free'),
    description: s__('LearnGitLab|Try all GitLab features for 30 days, no credit card required.'),
  },
  codeOwnersEnabled: {
    title: s__('LearnGitLab|Add code owners'),
    actionLabel: s__('LearnGitLab|Add code owners'),
    description: s__(
      'LearnGitLab|Prevent unexpected changes to important assets by assigning ownership of files and paths.',
    ),
    trialRequired: true,
  },
  requiredMrApprovalsEnabled: {
    title: s__('LearnGitLab|Add merge request approval'),
    actionLabel: s__('LearnGitLab|Enable require merge approvals'),
    description: s__('LearnGitLab|Route code reviews to the right reviewers, every time.'),
    trialRequired: true,
  },
  mergeRequestCreated: {
    title: s__('LearnGitLab|Submit a merge request'),
    actionLabel: s__('LearnGitLab|Submit a merge request (MR)'),
    description: s__('LearnGitLab|Review and edit proposed changes to source code.'),
  },
  securityScanEnabled: {
    title: s__('LearnGitLab|Run a security scan'),
    actionLabel: s__('LearnGitLab|Run a Security scan'),
    description: s__('LearnGitLab|Scan your code to uncover vulnerabilities before deploying.'),
  },
};
