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
    sections,
    fields,
    inheritFromId,
    integrationLevel,
    cancelPath,
    testPath,
    resetPath,
    formPath,
    vulnerabilitiesIssuetype,
    jiraIssueTransitionAutomatic,
    jiraIssueTransitionId,
    redirectTo,
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
    formPath,
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
    sections: JSON.parse(sections, { deep: true }),
    fields: convertObjectPropsToCamelCase(JSON.parse(fields), { deep: true }),
    inheritFromId: parseInt(inheritFromId, 10),
    integrationLevel,
    id: parseInt(id, 10),
    redirectTo,
  };
}

export default function initIntegrationSettingsForm() {
  const customSettingsEl = document.querySelector('.js-vue-integration-settings');
  const defaultSettingsEl = document.querySelector('.js-vue-default-integration-settings');

  if (!customSettingsEl) {
    return null;
  }

  const customSettingsProps = parseDatasetToProps(customSettingsEl.dataset);
  const initialState = {
    defaultState: null,
    customState: customSettingsProps,
  };
  if (defaultSettingsEl) {
    initialState.defaultState = Object.freeze(parseDatasetToProps(defaultSettingsEl.dataset));
  }

  // Here, we capture the "helpHtml", so we can pass it to the Vue component
  // to position it where ever it wants.
  // Because this node is a _child_ of `el`, it will be removed when the Vue component is mounted,
  // so we don't need to manually remove it.
  const helpHtml = customSettingsEl.querySelector('.js-integration-help-html')?.innerHTML;

  return new Vue({
    el: customSettingsEl,
    name: 'IntegrationEditRoot',
    store: createStore(initialState),
    provide: {
      helpHtml,
    },
    render(createElement) {
      return createElement(IntegrationForm);
    },
  });
}
