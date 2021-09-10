import {
  MSG_ISSUES_ASSIGNED_TO_ME,
  MSG_ISSUES_IVE_CREATED,
  MSG_MR_ASSIGNED_TO_ME,
  MSG_MR_IM_REVIEWER,
  MSG_MR_IVE_CREATED,
} from '../constants';

export const scopedIssuesPath = (state) => {
  return (
    state.searchContext.project_metadata?.issues_path ||
    state.searchContext.group_metadata?.issues_path ||
    state.issuesPath
  );
};

export const scopedMRPath = (state) => {
  return (
    state.searchContext.project_metadata?.mr_path ||
    state.searchContext.group_metadata?.mr_path ||
    state.mrPath
  );
};

export const defaultSearchOptions = (state, getters) => {
  const userName = gon.current_username;

  return [
    {
      title: MSG_ISSUES_ASSIGNED_TO_ME,
      url: `${getters.scopedIssuesPath}/?assignee_username=${userName}`,
    },
    {
      title: MSG_ISSUES_IVE_CREATED,
      url: `${getters.scopedIssuesPath}/?author_username=${userName}`,
    },
    {
      title: MSG_MR_ASSIGNED_TO_ME,
      url: `${getters.scopedMRPath}/?assignee_username=${userName}`,
    },
    {
      title: MSG_MR_IM_REVIEWER,
      url: `${getters.scopedMRPath}/?reviewer_username=${userName}`,
    },
    {
      title: MSG_MR_IVE_CREATED,
      url: `${getters.scopedMRPath}/?author_username=${userName}`,
    },
  ];
};
