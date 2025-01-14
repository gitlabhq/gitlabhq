const WORK_ITEM_TYPE_INCIDENT = 'incident';
const WORK_ITEM_TYPE_ISSUE = 'issue';

export const SUPPORT_BOT_USERNAME = 'support-bot';

export const issuableInitialDataById = (id) => {
  try {
    const el = document.getElementById(id);
    if (!el?.dataset?.initial) return null;

    return JSON.parse(el.dataset.initial);
  } catch {
    return null;
  }
};

const isIssuableIncident = (data) => {
  return data?.issueType === WORK_ITEM_TYPE_INCIDENT;
};

const isIssuableServiceDeskIssue = (data) => {
  return data?.issueType === WORK_ITEM_TYPE_ISSUE && data?.authorUsername === SUPPORT_BOT_USERNAME;
};

export const isLegacyIssueType = (issuableData) => {
  return isIssuableIncident(issuableData) || isIssuableServiceDeskIssue(issuableData);
};
