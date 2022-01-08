import { last } from 'lodash';
import { JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY } from './constants';

export const IMPORT_STATE = {
  FAILED: 'failed',
  FINISHED: 'finished',
  NONE: 'none',
  SCHEDULED: 'scheduled',
  STARTED: 'started',
};

export const isInProgress = (state) =>
  state === IMPORT_STATE.SCHEDULED || state === IMPORT_STATE.STARTED;

export const isFinished = (state) => state === IMPORT_STATE.FINISHED;

/**
 * Converts the list of Jira projects into a format consumable by GlFormSelect.
 *
 * @param {Object[]} projects - List of Jira projects
 * @param {string} projects[].key - Jira project key
 * @param {string} projects[].name - Jira project name
 * @returns {Object[]} - List of Jira projects in a format consumable by GlFormSelect
 */
export const extractJiraProjectsOptions = (projects) =>
  projects.map(({ key, name }) => ({ text: `${name} (${key})`, value: key }));

/**
 * Calculates the label title for the most recent Jira import.
 *
 * @param {Object[]} jiraImports - List of Jira imports
 * @param {string} jiraImports[].jiraProjectKey - Jira project key
 * @returns {string} - A label title
 */
const calculateJiraImportLabelTitle = (jiraImports) => {
  const mostRecentJiraProjectKey = last(jiraImports)?.jiraProjectKey;
  const jiraProjectImportCount = jiraImports.filter(
    (jiraImport) => jiraImport.jiraProjectKey === mostRecentJiraProjectKey,
  ).length;
  return `jira-import::${mostRecentJiraProjectKey}-${jiraProjectImportCount}`;
};

/**
 * Finds the label color from a list of labels.
 *
 * @param {string} labelTitle - Label title
 * @param {Object[]} labels - List of labels
 * @param {string} labels[].title - Label title
 * @param {string} labels[].color - Label color
 * @returns {string} - The label color associated with the given labelTitle
 */
const calculateJiraImportLabelColor = (labelTitle, labels) =>
  labels.find((label) => label.title === labelTitle)?.color;

/**
 * Calculates the label for the most recent Jira import.
 *
 * @param {Object[]} jiraImports - List of Jira imports
 * @param {string} jiraImports[].jiraProjectKey - Jira project key
 * @param {Object[]} labels - List of labels
 * @param {string} labels[].title - Label title
 * @param {string} labels[].color - Label color
 * @returns {{color: string, title: string}} - A label object containing a label color and title
 */
export const calculateJiraImportLabel = (jiraImports, labels) => {
  const title = calculateJiraImportLabelTitle(jiraImports);
  return {
    color: calculateJiraImportLabelColor(title, labels),
    title,
  };
};

/**
 * Calculates whether the Jira import success alert should be shown.
 *
 * @param {string} labelTitle - Jira import label, for checking localStorage
 * @param {string} importStatus - Jira import status
 * @returns {boolean} - A boolean indicating whether to show the success alert
 */
export const shouldShowFinishedAlert = (labelTitle, importStatus) => {
  const finishedAlertHideMap =
    JSON.parse(localStorage.getItem(JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY)) || {};

  const shouldHide = finishedAlertHideMap[labelTitle];

  return !shouldHide && isFinished(importStatus);
};

/**
 * Updates the localStorage map to permanently hide the Jira import success alert
 *
 * @param {string} labelTitle - Jira import label, for checking localStorage
 */
export const setFinishedAlertHideMap = (labelTitle) => {
  const finishedAlertHideMap =
    JSON.parse(localStorage.getItem(JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY)) || {};

  finishedAlertHideMap[labelTitle] = true;

  localStorage.setItem(
    JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY,
    JSON.stringify(finishedAlertHideMap),
  );
};
