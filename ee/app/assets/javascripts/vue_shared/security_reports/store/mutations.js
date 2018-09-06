import Vue from 'vue';
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
    Vue.set(state.blobPath, 'head', path);
  },

  [types.SET_BASE_BLOB_PATH](state, path) {
    Vue.set(state.blobPath, 'base', path);
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

  [types.SET_CAN_CREATE_ISSUE_PERMISSION](state, permission) {
    state.canCreateIssuePermission = permission;
  },

  [types.SET_CAN_CREATE_FEEDBACK_PERMISSION](state, permission) {
    state.canCreateFeedbackPermission = permission;
  },

  // SAST
  [types.SET_SAST_HEAD_PATH](state, path) {
    Vue.set(state.sast.paths, 'head', path);
  },

  [types.SET_SAST_BASE_PATH](state, path) {
    Vue.set(state.sast.paths, 'base', path);
  },

  [types.REQUEST_SAST_REPORTS](state) {
    Vue.set(state.sast, 'isLoading', true);
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

      Vue.set(state.sast, 'newIssues', newIssues);
      Vue.set(state.sast, 'resolvedIssues', resolvedIssues);
      Vue.set(state.sast, 'allIssues', allIssues);
      Vue.set(state.sast, 'isLoading', false);

      state.summaryCounts.added += newIssues.length;
      state.summaryCounts.fixed += resolvedIssues.length;
    } else if (reports.head && !reports.base) {
      const newIssues = parseSastIssues(reports.head, reports.enrichData, state.blobPath.head);

      Vue.set(state.sast, 'newIssues', newIssues);
      Vue.set(state.sast, 'isLoading', false);

      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_SAST_REPORTS_ERROR](state) {
    Vue.set(state.sast, 'isLoading', false);
    Vue.set(state.sast, 'hasError', true);
  },

  // SAST CONTAINER
  [types.SET_SAST_CONTAINER_HEAD_PATH](state, path) {
    Vue.set(state.sastContainer.paths, 'head', path);
  },

  [types.SET_SAST_CONTAINER_BASE_PATH](state, path) {
    Vue.set(state.sastContainer.paths, 'base', path);
  },

  [types.REQUEST_SAST_CONTAINER_REPORTS](state) {
    Vue.set(state.sastContainer, 'isLoading', true);
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

      Vue.set(state.sastContainer, 'newIssues', newIssues);
      Vue.set(state.sastContainer, 'resolvedIssues', resolvedIssues);
      Vue.set(state.sastContainer, 'isLoading', false);

      state.summaryCounts.added += newIssues.length;
      state.summaryCounts.fixed += resolvedIssues.length;
    } else if (reports.head && !reports.base) {
      const newIssues = getUnapprovedVulnerabilities(
        parseSastContainer(reports.head.vulnerabilities, reports.enrichData),
        reports.head.unapproved,
      );

      Vue.set(state.sastContainer, 'newIssues', newIssues);
      Vue.set(state.sastContainer, 'isLoading', false);

      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_SAST_CONTAINER_ERROR](state) {
    Vue.set(state.sastContainer, 'isLoading', false);
    Vue.set(state.sastContainer, 'hasError', true);
  },

  // DAST

  [types.SET_DAST_HEAD_PATH](state, path) {
    Vue.set(state.dast.paths, 'head', path);
  },

  [types.SET_DAST_BASE_PATH](state, path) {
    Vue.set(state.dast.paths, 'base', path);
  },

  [types.REQUEST_DAST_REPORTS](state) {
    Vue.set(state.dast, 'isLoading', true);
  },

  [types.RECEIVE_DAST_REPORTS](state, reports) {
    if (reports.head && reports.base) {
      const headIssues = parseDastIssues(reports.head.site.alerts, reports.enrichData);
      const baseIssues = parseDastIssues(reports.base.site.alerts, reports.enrichData);
      const filterKey = 'pluginid';
      const newIssues = filterByKey(headIssues, baseIssues, filterKey);
      const resolvedIssues = filterByKey(baseIssues, headIssues, filterKey);

      Vue.set(state.dast, 'newIssues', newIssues);
      Vue.set(state.dast, 'resolvedIssues', resolvedIssues);
      Vue.set(state.dast, 'isLoading', false);
      state.summaryCounts.added += newIssues.length;

      state.summaryCounts.fixed += resolvedIssues.length;
    } else if (reports.head && reports.head.site && !reports.base) {
      const newIssues = parseDastIssues(reports.head.site.alerts, reports.enrichData);

      Vue.set(state.dast, 'newIssues', newIssues);
      Vue.set(state.dast, 'isLoading', false);

      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_DAST_ERROR](state) {
    Vue.set(state.dast, 'isLoading', false);
    Vue.set(state.dast, 'hasError', true);
  },

  // DEPENDECY SCANNING

  [types.SET_DEPENDENCY_SCANNING_HEAD_PATH](state, path) {
    Vue.set(state.dependencyScanning.paths, 'head', path);
  },

  [types.SET_DEPENDENCY_SCANNING_BASE_PATH](state, path) {
    Vue.set(state.dependencyScanning.paths, 'base', path);
  },

  [types.REQUEST_DEPENDENCY_SCANNING_REPORTS](state) {
    Vue.set(state.dependencyScanning, 'isLoading', true);
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

      Vue.set(state.dependencyScanning, 'newIssues', newIssues);
      Vue.set(state.dependencyScanning, 'resolvedIssues', resolvedIssues);
      Vue.set(state.dependencyScanning, 'allIssues', allIssues);
      Vue.set(state.dependencyScanning, 'isLoading', false);

      state.summaryCounts.added += newIssues.length;
      state.summaryCounts.fixed += resolvedIssues.length;
    }

    if (reports.head && !reports.base) {
      const newIssues = parseDependencyScanningIssues(reports.head, reports.enrichData,
        state.blobPath.head);
      Vue.set(state.dependencyScanning, 'newIssues', newIssues);
      Vue.set(state.dependencyScanning, 'isLoading', false);

      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_DEPENDENCY_SCANNING_ERROR](state) {
    Vue.set(state.dependencyScanning, 'isLoading', false);
    Vue.set(state.dependencyScanning, 'hasError', true);
  },

  [types.SET_ISSUE_MODAL_DATA](state, payload) {
    const { issue, status } = payload;

    Vue.set(state.modal, 'title', issue.title);
    Vue.set(state.modal.data.description, 'value', issue.description);
    Vue.set(state.modal.data.file, 'value', issue.location && issue.location.file);
    Vue.set(state.modal.data.file, 'url', issue.urlPath);
    Vue.set(state.modal.data.className, 'value', issue.location && issue.location.class);
    Vue.set(state.modal.data.methodName, 'value', issue.location && issue.location.method);
    Vue.set(state.modal.data.namespace, 'value', issue.namespace);

    if (issue.identifiers && issue.identifiers.length > 0) {
      Vue.set(state.modal.data.identifiers, 'value', issue.identifiers);
    } else {
      // Force a null value for identifiers to avoid showing an empty array
      Vue.set(state.modal.data.identifiers, 'value', null);
    }

    Vue.set(state.modal.data.severity, 'value', issue.severity);
    Vue.set(state.modal.data.confidence, 'value', issue.confidence);
    Vue.set(state.modal.data.solution, 'value', issue.solution);

    if (issue.links && issue.links.length > 0) {
      Vue.set(state.modal.data.links, 'value', issue.links);
    } else {
      // Force a null value for links to avoid showing an empty array
      Vue.set(state.modal.data.links, 'value', null);
    }

    Vue.set(state.modal.data.instances, 'value', issue.instances);
    Vue.set(state.modal, 'vulnerability', issue);
    Vue.set(state.modal, 'isResolved', status === 'success');

    // clear previous state
    Vue.set(state.modal, 'error', null);
  },

  [types.REQUEST_DISMISS_ISSUE](state) {
    Vue.set(state.modal, 'isDismissingIssue', true);
    // reset error in case previous state was error
    Vue.set(state.modal, 'error', null);
  },

  [types.RECEIVE_DISMISS_ISSUE_SUCCESS](state) {
    Vue.set(state.modal, 'isDismissingIssue', false);
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
    Vue.set(state.modal, 'error', error);
    Vue.set(state.modal, 'isDismissingIssue', false);
  },

  [types.REQUEST_CREATE_ISSUE](state) {
    Vue.set(state.modal, 'isCreatingNewIssue', true);
    // reset error in case previous state was error
    Vue.set(state.modal, 'error', null);
  },

  [types.RECEIVE_CREATE_ISSUE_SUCCESS](state) {
    Vue.set(state.modal, 'isCreatingNewIssue', false);
  },

  [types.RECEIVE_CREATE_ISSUE_ERROR](state, error) {
    Vue.set(state.modal, 'error', error);
    Vue.set(state.modal, 'isCreatingNewIssue', false);
  },
};
