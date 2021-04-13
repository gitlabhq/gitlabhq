import { s__ } from '~/locale';

export const ACTION_LABELS = {
  gitWrite: {
    title: s__('LearnGitLab|Create or import a repository'),
    actionLabel: s__('LearnGitLab|Create or import a repository'),
    description: s__('LearnGitLab|Create or import your first repository into your new project.'),
    section: 'workspace',
    position: 1,
  },
  userAdded: {
    title: s__('LearnGitLab|Invite your colleagues'),
    actionLabel: s__('LearnGitLab|Invite your colleagues'),
    description: s__(
      'LearnGitLab|GitLab works best as a team. Invite your colleague to enjoy all features.',
    ),
    section: 'workspace',
    position: 0,
  },
  pipelineCreated: {
    title: s__('LearnGitLab|Set up CI/CD'),
    actionLabel: s__('LearnGitLab|Set-up CI/CD'),
    description: s__('LearnGitLab|Save time by automating your integration and deployment tasks.'),
    section: 'workspace',
    position: 2,
  },
  trialStarted: {
    title: s__('LearnGitLab|Start a free Ultimate trial'),
    actionLabel: s__('LearnGitLab|Try GitLab Ultimate for free'),
    description: s__('LearnGitLab|Try all GitLab features for 30 days, no credit card required.'),
    section: 'workspace',
    position: 3,
  },
  codeOwnersEnabled: {
    title: s__('LearnGitLab|Add code owners'),
    actionLabel: s__('LearnGitLab|Add code owners'),
    description: s__(
      'LearnGitLab|Prevent unexpected changes to important assets by assigning ownership of files and paths.',
    ),
    trialRequired: true,
    section: 'workspace',
    position: 4,
  },
  requiredMrApprovalsEnabled: {
    title: s__('LearnGitLab|Add merge request approval'),
    actionLabel: s__('LearnGitLab|Enable require merge approvals'),
    description: s__('LearnGitLab|Route code reviews to the right reviewers, every time.'),
    trialRequired: true,
    section: 'workspace',
    position: 5,
  },
  mergeRequestCreated: {
    title: s__('LearnGitLab|Submit a merge request'),
    actionLabel: s__('LearnGitLab|Submit a merge request (MR)'),
    description: s__('LearnGitLab|Review and edit proposed changes to source code.'),
    section: 'plan',
    position: 1,
  },
  securityScanEnabled: {
    title: s__('LearnGitLab|Run a Security scan using CI/CD'),
    actionLabel: s__('LearnGitLab|Run a Security scan using CI/CD'),
    description: s__('LearnGitLab|Scan your code to uncover vulnerabilities before deploying.'),
    section: 'deploy',
    position: 1,
  },
  issueCreated: {
    title: s__('LearnGitLab|Create an issue'),
    actionLabel: s__('LearnGitLab|Create an issue'),
    description: s__(
      'LearnGitLab|Create/import issues (tickets) to collaborate on ideas and plan work.',
    ),
    section: 'plan',
    position: 0,
  },
};

export const ACTION_SECTIONS = {
  workspace: {
    title: s__('LearnGitLab|Set up your workspace'),
    description: s__(
      "LearnGitLab|Complete these tasks first so you can enjoy GitLab's features to their fullest:",
    ),
  },
  plan: {
    title: s__('LearnGitLab|Plan and execute'),
    description: s__(
      'LearnGitLab|Create a workflow for your new workspace, and learn how GitLab features work together:',
    ),
  },
  deploy: {
    title: s__('LearnGitLab|Deploy'),
    description: s__(
      'LearnGitLab|Use your new GitLab workflow to deploy your application, monitor its health, and keep it secure:',
    ),
  },
};
