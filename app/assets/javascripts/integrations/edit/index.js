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
    learnMorePath,
    triggerEvents,
    fields,
    inheritFromId,
    integrationLevel,
    cancelPath,
    testPath,
    resetPath,
    ...booleanAttributes
  } = data;
  const {
    showActive,
    activated,
    editable,
    canTest,
    commitEvents,
    mergeRequestEvents,
    enableComments,
    showJiraIssuesIntegration,
    enableJiraIssues,
    gitlabIssuesEnabled,
  } = parseBooleanInData(booleanAttributes);

  return {
    initialActivated: activated,
    showActive,
    type,
    cancelPath,
    editable,
    canTest,
    testPath,
    resetPath,
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
      gitlabIssuesEnabled,
      upgradePlanPath,
      editProjectPath,
    },
    learnMorePath,
    triggerEvents: JSON.parse(triggerEvents),
    fields: JSON.parse(fields),
    inheritFromId: parseInt(inheritFromId, 10),
    integrationLevel,
    id: parseInt(id, 10),
  };
}

export default (el, defaultEl) => {
  if (!el) {
    return null;
  }

  const props = parseDatasetToProps(el.dataset);

  const initialState = {
    defaultState: null,
    customState: props,
  };

  if (defaultEl) {
    initialState.defaultState = Object.freeze(parseDatasetToProps(defaultEl.dataset));
  }

  return new Vue({
    el,
    store: createStore(initialState),
    render(createElement) {
      return createElement(IntegrationForm);
    },
  });
};
