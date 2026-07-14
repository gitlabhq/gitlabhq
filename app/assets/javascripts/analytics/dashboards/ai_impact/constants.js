import { pick } from 'lodash-es';
import { s__ } from '~/locale';
import { AI_METRICS, UNITS } from '~/analytics/shared/constants';

import { helpPagePath } from '~/helpers/help_page_helper';
import { TABLE_METRICS, PIPELINE_ANALYTICS_TABLE_METRICS } from '~/analytics/dashboards/constants';

export const SUPPORTED_AI_METRICS = [
  AI_METRICS.DUO_USED_COUNT,
  AI_METRICS.DUO_AGENT_PLATFORM_FLOWS,
  AI_METRICS.DUO_AGENT_PLATFORM_CHATS,
  AI_METRICS.DUO_CHAT_USERS_COUNT,
  AI_METRICS.DUO_RCA_USERS_COUNT,
  AI_METRICS.DUO_REVIEW_REQUESTS_COUNT,
  AI_METRICS.DUO_REVIEW_COMMENT_COUNT,
  AI_METRICS.CODE_SUGGESTIONS_USERS_COUNT,
  AI_METRICS.CODE_SUGGESTIONS_ACCEPTANCE_RATE,
];
export const HIDE_METRIC_DRILL_DOWN = [
  AI_METRICS.CODE_SUGGESTIONS_USERS_COUNT,
  AI_METRICS.CODE_SUGGESTIONS_ACCEPTANCE_RATE,
  AI_METRICS.DUO_CHAT_USERS_COUNT,
  AI_METRICS.DUO_RCA_USERS_COUNT,
  AI_METRICS.DUO_USED_COUNT,
  AI_METRICS.DUO_REVIEW_REQUESTS_COUNT,
  AI_METRICS.DUO_REVIEW_COMMENT_COUNT,
  AI_METRICS.DUO_AGENT_PLATFORM_CHATS,
  AI_METRICS.DUO_AGENT_PLATFORM_FLOWS,
];

// The AI impact metrics supported for over time tiles
export const AI_IMPACT_OVER_TIME_METRICS = {
  [AI_METRICS.DUO_AGENT_PLATFORM_CHATS]: {
    label: s__('AiImpactAnalytics|Duo Agent Platform chats'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_USED_COUNT]: {
    label: s__('AiImpactAnalytics|Duo users'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_AGENT_PLATFORM_AGENTS_FLOWS_USERS_COUNT]: {
    label: s__('AiImpactAnalytics|GitLab Duo agent/flow users'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_POWER_USERS_COUNT]: {
    label: s__('AiImpactAnalytics|GitLab Duo power users'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_PIPELINES_RATE]: {
    label: s__('AiImpactAnalytics|Pipelines using GitLab Duo features'),
    units: UNITS.PERCENT,
  },
};

export const AI_IMPACT_USAGE_METRICS = {
  ...AI_IMPACT_OVER_TIME_METRICS,
  [AI_METRICS.CODE_SUGGESTIONS_ACCEPTANCE_RATE]: {
    label: s__('AiImpactAnalytics|Code Suggestions acceptance rate'),
    units: UNITS.PERCENT,
  },
  [AI_METRICS.DUO_RCA_USERS_COUNT]: {
    label: s__('AiImpactAnalytics|Root Cause Analysis usage'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_CHAT_USERS_COUNT]: {
    label: s__('AiImpactAnalytics|Chat (non-agentic) usage'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.CODE_SUGGESTIONS_USERS_COUNT]: {
    label: s__('AiImpactAnalytics|Code Suggestions usage'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_REVIEW_REQUESTS_COUNT]: {
    label: s__('AiImpactAnalytics|Code Review requests'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_REVIEW_COMMENT_COUNT]: {
    label: s__('AiImpactAnalytics|Code Review comments'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_USED_COUNT]: {
    label: s__('AiImpactAnalytics|Feature usage'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_AGENT_PLATFORM_FLOWS]: {
    label: s__('AiImpactAnalytics|Agent Platform flows'),
    units: UNITS.COUNT,
  },
  [AI_METRICS.DUO_AGENT_PLATFORM_CHATS]: {
    label: s__('AiImpactAnalytics|Agent Platform chats'),
    units: UNITS.COUNT,
  },
};

export const AI_IMPACT_TABLE_METRICS = {
  ...TABLE_METRICS,
  ...PIPELINE_ANALYTICS_TABLE_METRICS,
  ...pick(AI_IMPACT_USAGE_METRICS, SUPPORTED_AI_METRICS),
};

export const DATA_TABLE_METRICS = AI_IMPACT_TABLE_METRICS;

export const AI_IMPACT_OVER_TIME_METRICS_TOOLTIPS = {
  [AI_METRICS.DUO_AGENT_PLATFORM_CHATS]: {
    description: s__(
      'AiImpactAnalytics|Number of chat sessions in Duo Agent Platform. %{linkStart}Learn more%{linkEnd}.',
    ),
    descriptionLink: helpPagePath('user/gitlab_duo_chat/agentic_chat'),
  },
  [AI_METRICS.DUO_USED_COUNT]: {
    description: s__(
      'AiImpactAnalytics|Number of users who used at least one GitLab Duo or GitLab Duo Agent Platform feature.',
    ),
  },
  [AI_METRICS.DUO_AGENT_PLATFORM_AGENTS_FLOWS_USERS_COUNT]: {
    description: s__(
      'AiImpactAnalytics|Number of users who used at least one GitLab Duo agent or flow.',
    ),
  },
  [AI_METRICS.DUO_POWER_USERS_COUNT]: {
    description: s__(
      'AiImpactAnalytics|Number of users that used at least three GitLab Duo features.',
    ),
  },
  [AI_METRICS.DUO_PIPELINES_RATE]: {
    description: s__(
      'AiImpactAnalytics|Percentage of CI/CD pipelines that used one or more GitLab Duo features during execution.',
    ),
  },
};

const duoReviewDataNotAvailableTooltip = {
  startDate: new Date('2025-08-21'),
  message: s__(
    'AiImpactAnalytics|Data available after upgrade to GitLab 18.3. %{linkStart}Learn more%{linkEnd}.',
  ),
  link: helpPagePath('user/analytics/duo_and_sdlc_trends', {
    anchor: 'gitlab-duo-usage-metrics',
  }),
};

const agentPlatformDataNotAvailableTooltip = {
  startDate: new Date('2025-09-01'),
  message: s__(
    'AiImpactAnalytics|Data available after upgrade to GitLab 18.7. %{linkStart}Learn more%{linkEnd}.',
  ),
  link: helpPagePath('user/analytics/duo_and_sdlc_trends', {
    anchor: 'gitlab-duo-usage-metrics',
  }),
};

export const AI_IMPACT_DATA_NOT_AVAILABLE_TOOLTIPS = {
  // Code suggestions usage only started being tracked April 4, 2024
  // https://gitlab.com/gitlab-org/gitlab/-/issues/456108
  [AI_METRICS.CODE_SUGGESTIONS_USERS_COUNT]: {
    startDate: new Date('2024-04-04'),
    message: s__(
      'AiImpactAnalytics|The usage data may be incomplete due to backend calculations starting after upgrade to GitLab 16.11. For more information, see %{linkStart}epic 12978%{linkEnd}.',
    ),
    link: 'https://gitlab.com/groups/gitlab-org/-/epics/12978',
  },
  // Duo RCA usage only started being tracked April 23, 2025
  // https://gitlab.com/gitlab-org/gitlab/-/issues/486523
  [AI_METRICS.DUO_RCA_USERS_COUNT]: {
    startDate: new Date('2025-04-23'),
    message: s__(
      'AiImpactAnalytics|Data available after upgrade to GitLab 18.0. %{linkStart}Learn more%{linkEnd}.',
    ),
    link: helpPagePath('user/analytics/duo_and_sdlc_trends', {
      anchor: 'gitlab-duo-usage-metrics',
    }),
  },
  [AI_METRICS.DUO_REVIEW_REQUESTS_COUNT]: duoReviewDataNotAvailableTooltip,
  [AI_METRICS.DUO_REVIEW_COMMENT_COUNT]: duoReviewDataNotAvailableTooltip,
  [AI_METRICS.DUO_AGENT_PLATFORM_FLOWS]: agentPlatformDataNotAvailableTooltip,
  [AI_METRICS.DUO_AGENT_PLATFORM_CHATS]: agentPlatformDataNotAvailableTooltip,
};
