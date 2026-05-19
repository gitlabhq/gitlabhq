export const issuableInitialDataById = (id) => {
  try {
    const el = document.getElementById(id);
    if (!el?.dataset?.initial) return null;

    return JSON.parse(el.dataset.initial);
  } catch {
    return null;
  }
};

export const isLegacyIssueType = (issuableData) => {
  return issuableData?.isIncidentManagement || issuableData?.isServiceDesk;
};
