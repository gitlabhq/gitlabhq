import { helpPagePath } from '~/helpers/help_page_helper';

// eslint-disable-next-line @gitlab/no-hardcoded-urls
export const DUO_CHAT_QUICK_ACTION_SUMMARIZE = '/summarize_comments';

export const DUO_CHAT_AGENT_PLANNER = 'Planner';

export const duoHelpPath = helpPagePath('user/gitlab_duo/_index');
export const amazonQHelpPath = helpPagePath('user/duo_amazon_q/_index.md');
export const duoContextExclusionHelpPath = helpPagePath('user/gitlab_duo/context', {
  anchor: 'exclude-context-from-code-review',
});
export const duoFlowHelpPath = helpPagePath('user/duo_agent_platform/flows/_index.md');

// Values that can appear in the Gitlab Duo settings `visibleSettings` allowlist.
// ALL_SETTINGS renders every Duo setting; named identifiers limit rendering to
// just the named settings (e.g. Security Managers, who may update only the SAST
// Vulnerability Resolution setting).
export const ALL_SETTINGS = 'all';
export const DUO_SAST_VR_WORKFLOW_ENABLED = 'duoSastVrWorkflowEnabled';
export const DUO_SAST_FALSE_POSITIVE_DETECTION_ENABLED = 'duoSastFalsePositiveDetectionEnabled';
export const DUO_SECRET_DETECTION_FP_ENABLED = 'duoSecretDetectionFpEnabled';
export const DUO_VULNERABILITY_CONTEXT_ANALYSIS_ENABLED = 'duoVulnerabilityContextAnalysisEnabled';
