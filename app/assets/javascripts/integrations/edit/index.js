import Vue from 'vue';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';

import IntegrationForm from './components/integration_form.vue';
import { createStore } from './store';

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
    vulnerabilitiesIssuetype,
    jiraIssueTransitionAutomatic,
    jiraIssueTransitionId,
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
    showJiraVulnerabilitiesIntegration,
    enableJiraIssues,
    enableJiraVulnerabilities,
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
      initialJiraIssueTransitionAutomatic: jiraIssueTransitionAutomatic,
      initialJiraIssueTransitionId: jiraIssueTransitionId,
    },
    jiraIssuesProps: {
      showJiraIssuesIntegration,
      showJiraVulnerabilitiesIntegration,
      initialEnableJiraIssues: enableJiraIssues,
      initialEnableJiraVulnerabilities: enableJiraVulnerabilities,
      initialVulnerabilitiesIssuetype: vulnerabilitiesIssuetype,
      initialProjectKey: projectKey,
      gitlabIssuesEnabled,
      upgradePlanPath,
      editProjectPath,
    },
    learnMorePath,
    triggerEvents: JSON.parse(triggerEvents),
    fields: convertObjectPropsToCamelCase(JSON.parse(fields), { deep: true }),
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

  // Here, we capture the "helpHtml", so we can pass it to the Vue component
  // to position it where ever it wants.
  // Because this node is a _child_ of `el`, it will be removed when the Vue component is mounted,
  // so we don't need to manually remove it.
  const helpHtml = el.querySelector('.js-integration-help-html')?.innerHTML;

  return new Vue({
    el,
    store: createStore(initialState),
    render(createElement) {
      return createElement(IntegrationForm, {
        props: {
          helpHtml,
        },
      });
    },
  });
};
