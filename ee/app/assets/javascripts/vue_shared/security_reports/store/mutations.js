/* eslint-disable no-param-reassign */

import * as types from './mutation_types';
import {
  parseSastIssues,
  parseDependencyScanningIssues,
  filterByKey,
  parseSastContainer,
  parseDastIssues,
  getUnapprovedVulnerabilities,
  findIssueIndex,
} from './utils';

export default {
  [types.SET_HEAD_BLOB_PATH](state, path) {
    state.blobPath.head = path;
  },

  [types.SET_BASE_BLOB_PATH](state, path) {
    state.blobPath.base = path;
  },

  [types.SET_VULNERABILITY_FEEDBACK_PATH](state, path) {
    state.vulnerabilityFeedbackPath = path;
  },

  [types.SET_VULNERABILITY_FEEDBACK_HELP_PATH](state, path) {
    state.vulnerabilityFeedbackHelpPath = path;
  },

  [types.SET_PIPELINE_ID](state, id) {
    state.pipelineId = id;
  },

  // SAST
  [types.SET_SAST_HEAD_PATH](state, path) {
    state.sast.paths.head = path;
  },

  [types.SET_SAST_BASE_PATH](state, path) {
    state.sast.paths.base = path;
  },

  [types.REQUEST_SAST_REPORTS](state) {
    state.sast.isLoading = true;
  },

  /**
   * Compares sast results and returns the formatted report
   *
   * Sast has 3 types of issues: newIssues, resolvedIssues and allIssues.
   *
   * When we have both base and head:
   * - newIssues = head - base
   * - resolvedIssues = base - head
   * - allIssues = head - newIssues - resolvedIssues
   *
   * When we only have head
   * - newIssues = head
   * - resolvedIssues = 0
   * - allIssues = 0
   */
  [types.RECEIVE_SAST_REPORTS](state, reports) {
    if (reports.base && reports.head) {
      const filterKey = 'cve';
      const parsedHead = parseSastIssues(reports.head, reports.enrichData, state.blobPath.head);
      const parsedBase = parseSastIssues(reports.base, reports.enrichData, state.blobPath.base);

      const newIssues = filterByKey(parsedHead, parsedBase, filterKey);
      const resolvedIssues = filterByKey(parsedBase, parsedHead, filterKey);
      const allIssues = filterByKey(parsedHead, newIssues.concat(resolvedIssues), filterKey);

      state.sast.newIssues = newIssues;
      state.sast.resolvedIssues = resolvedIssues;
      state.sast.allIssues = allIssues;
      state.sast.isLoading = false;
      state.summaryCounts.added += newIssues.length;
      state.summaryCounts.fixed += resolvedIssues.length;
    } else if (reports.head && !reports.base) {
      const newIssues = parseSastIssues(reports.head, reports.enrichData, state.blobPath.head);

      state.sast.newIssues = newIssues;
      state.sast.isLoading = false;
      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_SAST_REPORTS_ERROR](state) {
    state.sast.isLoading = false;
    state.sast.hasError = true;
  },

  // SAST CONTAINER
  [types.SET_SAST_CONTAINER_HEAD_PATH](state, path) {
    state.sastContainer.paths.head = path;
  },

  [types.SET_SAST_CONTAINER_BASE_PATH](state, path) {
    state.sastContainer.paths.base = path;
  },

  [types.REQUEST_SAST_CONTAINER_REPORTS](state) {
    state.sastContainer.isLoading = true;
  },

  /**
   * For sast container we only render unapproved vulnerabilities.
   */
  [types.RECEIVE_SAST_CONTAINER_REPORTS](state, reports) {
    if (reports.base && reports.head) {
      const headIssues = getUnapprovedVulnerabilities(
        parseSastContainer(reports.head.vulnerabilities, reports.enrichData),
        reports.head.unapproved,
      );
      const baseIssues = getUnapprovedVulnerabilities(
        parseSastContainer(reports.base.vulnerabilities, reports.enrichData),
        reports.base.unapproved,
      );
      const filterKey = 'vulnerability';

      const newIssues = filterByKey(headIssues, baseIssues, filterKey);
      const resolvedIssues = filterByKey(baseIssues, headIssues, filterKey);

      state.sastContainer.newIssues = newIssues;
      state.sastContainer.resolvedIssues = resolvedIssues;
      state.sastContainer.isLoading = false;
      state.summaryCounts.added += newIssues.length;
      state.summaryCounts.fixed += resolvedIssues.length;
    } else if (reports.head && !reports.base) {
      const newIssues = getUnapprovedVulnerabilities(
        parseSastContainer(reports.head.vulnerabilities, reports.enrichData),
        reports.head.unapproved,
      );

      state.sastContainer.newIssues = newIssues;
      state.sastContainer.isLoading = false;
      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_SAST_CONTAINER_ERROR](state) {
    state.sastContainer.isLoading = false;
    state.sastContainer.hasError = true;
  },

  // DAST

  [types.SET_DAST_HEAD_PATH](state, path) {
    state.dast.paths.head = path;
  },

  [types.SET_DAST_BASE_PATH](state, path) {
    state.dast.paths.base = path;
  },

  [types.REQUEST_DAST_REPORTS](state) {
    state.dast.isLoading = true;
  },

  [types.RECEIVE_DAST_REPORTS](state, reports) {
    if (reports.head && reports.base) {
      const headIssues = parseDastIssues(reports.head.site.alerts, reports.enrichData);
      const baseIssues = parseDastIssues(reports.base.site.alerts, reports.enrichData);
      const filterKey = 'pluginid';
      const newIssues = filterByKey(headIssues, baseIssues, filterKey);
      const resolvedIssues = filterByKey(baseIssues, headIssues, filterKey);

      state.dast.newIssues = newIssues;
      state.dast.resolvedIssues = resolvedIssues;
      state.dast.isLoading = false;
      state.summaryCounts.added += newIssues.length;
      state.summaryCounts.fixed += resolvedIssues.length;
    } else if (reports.head && !reports.base) {
      const newIssues = parseDastIssues(reports.head.site.alerts, reports.enrichData);

      state.dast.newIssues = newIssues;
      state.dast.isLoading = false;
      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_DAST_ERROR](state) {
    state.dast.isLoading = false;
    state.dast.hasError = true;
  },

  // DEPENDECY SCANNING

  [types.SET_DEPENDENCY_SCANNING_HEAD_PATH](state, path) {
    state.dependencyScanning.paths.head = path;
  },

  [types.SET_DEPENDENCY_SCANNING_BASE_PATH](state, path) {
    state.dependencyScanning.paths.base = path;
  },

  [types.REQUEST_DEPENDENCY_SCANNING_REPORTS](state) {
    state.dependencyScanning.isLoading = true;
  },

  /**
   * Compares dependency scanning results and returns the formatted report
   *
   * Dependency report has 3 types of issues, newIssues, resolvedIssues and allIssues.
   *
   * When we have both base and head:
   * - newIssues = head - base
   * - resolvedIssues = base - head
   * - allIssues = head - newIssues - resolvedIssues
   *
   * When we only have head
   * - newIssues = head
   * - resolvedIssues = 0
   * - allIssues = 0
   */
  [types.RECEIVE_DEPENDENCY_SCANNING_REPORTS](state, reports) {
    if (reports.base && reports.head) {
      const filterKey = 'cve';
      const parsedHead = parseDependencyScanningIssues(reports.head, reports.enrichData,
        state.blobPath.head);
      const parsedBase = parseDependencyScanningIssues(reports.base, reports.enrichData,
        state.blobPath.base);

      const newIssues = filterByKey(parsedHead, parsedBase, filterKey);
      const resolvedIssues = filterByKey(parsedBase, parsedHead, filterKey);
      const allIssues = filterByKey(parsedHead, newIssues.concat(resolvedIssues), filterKey);

      state.dependencyScanning.newIssues = newIssues;
      state.dependencyScanning.resolvedIssues = resolvedIssues;
      state.dependencyScanning.allIssues = allIssues;
      state.dependencyScanning.isLoading = false;
      state.summaryCounts.added += newIssues.length;
      state.summaryCounts.fixed += resolvedIssues.length;
    }

    if (reports.head && !reports.base) {
      const newIssues = parseDependencyScanningIssues(reports.head, reports.enrichData,
        state.blobPath.head);
      state.dependencyScanning.newIssues = newIssues;
      state.dependencyScanning.isLoading = false;
      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_DEPENDENCY_SCANNING_ERROR](state) {
    state.dependencyScanning.isLoading = false;
    state.dependencyScanning.hasError = true;
  },

  [types.SET_ISSUE_MODAL_DATA](state, issue) {
    state.modal.title = issue.title;
    state.modal.data.description.value = issue.description;
    state.modal.data.file.value = issue.location && issue.location.file;
    state.modal.data.file.url = issue.urlPath;
    state.modal.data.className.value = issue.location && issue.location.class;
    state.modal.data.methodName.value = issue.location && issue.location.method;
    state.modal.data.namespace.value = issue.namespace;
    if (issue.identifiers && issue.identifiers.length > 0) {
      state.modal.data.identifiers.value = issue.identifiers;
    } else {
      // Force a null value for identifiers to avoid showing an empty array
      state.modal.data.identifiers.value = null;
    }
    state.modal.data.severity.value = issue.severity;
    state.modal.data.confidence.value = issue.confidence;
    state.modal.data.solution.value = issue.solution;
    if (issue.links && issue.links.length > 0) {
      state.modal.data.links.value = issue.links;
    } else {
      // Force a null value for links to avoid showing an empty array
      state.modal.data.links.value = null;
    }
    state.modal.data.instances.value = issue.instances;
    state.modal.vulnerability = issue;

    // clear previous state
    state.modal.error = null;
  },

  [types.REQUEST_DISMISS_ISSUE](state) {
    state.modal.isDismissingIssue = true;
    // reset error in case previous state was error
    state.modal.error = null;
  },

  [types.RECEIVE_DISMISS_ISSUE_SUCCESS](state) {
    state.modal.isDismissingIssue = false;
  },

  [types.UPDATE_SAST_ISSUE](state, issue) {
    // Find issue in the correct list and update it

    const newIssuesIndex = findIssueIndex(state.sast.newIssues, issue);
    if (newIssuesIndex !== -1) {
      state.sast.newIssues.splice(newIssuesIndex, 1, issue);
      return;
    }

    const resolvedIssuesIndex = findIssueIndex(state.sast.resolvedIssues, issue);
    if (resolvedIssuesIndex !== -1) {
      state.sast.resolvedIssues.splice(resolvedIssuesIndex, 1, issue);
      return;
    }

    const allIssuesIndex = findIssueIndex(state.sast.allIssues, issue);
    if (allIssuesIndex !== -1) {
      state.sast.allIssues.splice(allIssuesIndex, 1, issue);
    }
  },

  [types.UPDATE_DEPENDENCY_SCANNING_ISSUE](state, issue) {
    // Find issue in the correct list and update it

    const newIssuesIndex = findIssueIndex(state.dependencyScanning.newIssues, issue);
    if (newIssuesIndex !== -1) {
      state.dependencyScanning.newIssues.splice(newIssuesIndex, 1, issue);
      return;
    }

    const resolvedIssuesIndex = findIssueIndex(state.dependencyScanning.resolvedIssues, issue);
    if (resolvedIssuesIndex !== -1) {
      state.dependencyScanning.resolvedIssues.splice(resolvedIssuesIndex, 1, issue);
      return;
    }

    const allIssuesIndex = findIssueIndex(state.dependencyScanning.allIssues, issue);
    if (allIssuesIndex !== -1) {
      state.dependencyScanning.allIssues.splice(allIssuesIndex, 1, issue);
    }
  },

  [types.UPDATE_CONTAINER_SCANNING_ISSUE](state, issue) {
    // Find issue in the correct list and update it

    const newIssuesIndex = findIssueIndex(state.sastContainer.newIssues, issue);
    if (newIssuesIndex !== -1) {
      state.sastContainer.newIssues.splice(newIssuesIndex, 1, issue);
      return;
    }

    const resolvedIssuesIndex = findIssueIndex(state.sastContainer.resolvedIssues, issue);
    if (resolvedIssuesIndex !== -1) {
      state.sastContainer.resolvedIssues.splice(resolvedIssuesIndex, 1, issue);
    }
  },

  [types.UPDATE_DAST_ISSUE](state, issue) {
    // Find issue in the correct list and update it

    const newIssuesIndex = findIssueIndex(state.dast.newIssues, issue);
    if (newIssuesIndex !== -1) {
      state.dast.newIssues.splice(newIssuesIndex, 1, issue);
      return;
    }

    const resolvedIssuesIndex = findIssueIndex(state.dast.resolvedIssues, issue);
    if (resolvedIssuesIndex !== -1) {
      state.dast.resolvedIssues.splice(resolvedIssuesIndex, 1, issue);
    }
  },

  [types.RECEIVE_DISMISS_ISSUE_ERROR](state, error) {
    state.modal.error = error;
    state.modal.isDismissingIssue = false;
  },

  [types.REQUEST_CREATE_ISSUE](state) {
    state.modal.isCreatingNewIssue = true;
    // reset error in case previous state was error
    state.modal.error = null;
  },

  [types.RECEIVE_CREATE_ISSUE_SUCCESS](state) {
    state.modal.isCreatingNewIssue = false;
  },

  [types.RECEIVE_CREATE_ISSUE_ERROR](state, error) {
    state.modal.error = error;
    state.modal.isCreatingNewIssue = false;
  },
};
