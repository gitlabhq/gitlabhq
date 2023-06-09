import { __, s__ } from '~/locale';

export const i18n = {
  slackErrorMessage: __('Unable to build Slack link.'),
  gitlabLogoAlt: __('GitLab logo'),
  slackLogoAlt: __('Slack logo'),
  title: s__('SlackIntegration|GitLab for Slack'),
  dropdownLabel: s__('SlackIntegration|Select a GitLab project to link with your Slack workspace.'),
  dropdownButtonText: __('Continue'),
  noProjects: __('No projects available.'),
  noProjectsDescription: __('Make sure you have the correct permissions to link your project.'),
  learnMore: __('Learn more'),
  signInLabel: s__('JiraService|Sign in to GitLab to get started.'),
  signInButtonText: __('Sign in to GitLab'),
};
