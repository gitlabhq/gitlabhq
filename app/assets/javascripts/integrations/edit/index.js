import Vue from 'vue';
import { createStore } from './store';
import { parseBoolean } from '~/lib/utils/common_utils';
import IntegrationForm from './components/integration_form.vue';

function parseBooleanInData(data) {
  const result = {};
  Object.entries(data).forEach(([key, value]) => {
    result[key] = parseBoolean(value);
  });
  return result;
}

function parseDatasetToProps(data) {
  const {
    id,
    type,
    commentDetail,
    projectKey,
    upgradePlanPath,
    editProjectPath,
    triggerEvents,
    fields,
    inheritFromId,
    ...booleanAttributes
  } = data;
  const {
    showActive,
    activated,
    commitEvents,
    mergeRequestEvents,
    enableComments,
    showJiraIssuesIntegration,
    enableJiraIssues,
  } = parseBooleanInData(booleanAttributes);

  return {
    activeToggleProps: {
      initialActivated: activated,
    },
    showActive,
    type,
    triggerFieldsProps: {
      initialTriggerCommit: commitEvents,
      initialTriggerMergeRequest: mergeRequestEvents,
      initialEnableComments: enableComments,
      initialCommentDetail: commentDetail,
    },
    jiraIssuesProps: {
      showJiraIssuesIntegration,
      initialEnableJiraIssues: enableJiraIssues,
      initialProjectKey: projectKey,
      upgradePlanPath,
      editProjectPath,
    },
    triggerEvents: JSON.parse(triggerEvents),
    fields: JSON.parse(fields),
    inheritFromId: parseInt(inheritFromId, 10),
    id: parseInt(id, 10),
  };
}

export default (el, adminEl) => {
  if (!el) {
    return null;
  }

  const props = parseDatasetToProps(el.dataset);

  const initialState = {
    adminState: null,
    customState: props,
  };

  if (adminEl) {
    initialState.adminState = Object.freeze(parseDatasetToProps(adminEl.dataset));
  }

  return new Vue({
    el,
    store: createStore(initialState),
    render(createElement) {
      return createElement(IntegrationForm);
    },
  });
};
