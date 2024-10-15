import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';

import IntegrationForm from './components/integration_form.vue';
import { createStore } from './store';

Vue.use(GlToast);

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
    projectId,
    groupId,
    commentDetail,
    projectKey,
    projectKeys,
    learnMorePath,
    aboutPricingUrl,
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
    artifactRegistryPath,
    workloadIdentityFederationPath,
    workloadIdentityFederationProjectNumber,
    workloadIdentityPoolId,
    wlifIssuer,
    jwtClaims,
    redirectTo,
    upgradeSlackUrl,
    ...booleanAttributes
  } = data;
  const {
    manualActivation,
    activated,
    operating,
    activateDisabled,
    editable,
    canTest,
    commitEvents,
    mergeRequestEvents,
    enableComments,
    showJiraIssuesIntegration,
    showJiraVulnerabilitiesIntegration,
    enableJiraIssues,
    enableJiraVulnerabilities,
    shouldUpgradeSlack,
    customizeJiraIssueEnabled,
  } = parseBooleanInData(booleanAttributes);

  return {
    initialActivated: activated,
    operating,
    manualActivation,
    activateDisabled,
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
      initialProjectKeys: projectKeys,
      initialCustomizeJiraIssueEnabled: customizeJiraIssueEnabled,
    },
    googleArtifactManagementProps: {
      artifactRegistryPath,
      workloadIdentityFederationPath,
      workloadIdentityFederationProjectNumber,
      workloadIdentityPoolId,
    },
    learnMorePath,
    aboutPricingUrl,
    triggerEvents: JSON.parse(triggerEvents),
    sections: JSON.parse(sections),
    fields: convertObjectPropsToCamelCase(JSON.parse(fields), { deep: true }),
    inheritFromId: parseInt(inheritFromId, 10),
    integrationLevel,
    id: parseInt(id, 10),
    groupId: parseInt(groupId, 10),
    projectId: parseInt(projectId, 10),
    wlifIssuer,
    jwtClaims,
    redirectTo,
    shouldUpgradeSlack,
    upgradeSlackUrl,
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
    editable: customSettingsProps.editable && !customSettingsProps.shouldUpgradeSlack,
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
