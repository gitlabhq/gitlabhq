/* eslint-disable no-param-reassign */

import * as types from './mutation_types';
import {
  parseSastIssues,
  filterByKey,
  parseSastContainer,
  parseDastIssues,
  getUnapprovedVulnerabilities,
} from './utils';

export default {
  [types.SET_HEAD_BLOB_PATH](state, path) {
    state.blobPath.head = path;
  },

  [types.SET_BASE_BLOB_PATH](state, path) {
    state.blobPath.base = path;
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
      const parsedHead = parseSastIssues(reports.head, state.blobPath.head);
      const parsedBase = parseSastIssues(reports.base, state.blobPath.base);

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
      const newIssues = parseSastIssues(reports.head, state.blobPath.head);

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
        parseSastContainer(reports.head.vulnerabilities),
        reports.head.unapproved,
      );
      const baseIssues = getUnapprovedVulnerabilities(
        parseSastContainer(reports.base.vulnerabilities),
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
        parseSastContainer(reports.head.vulnerabilities),
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
      const headIssues = parseDastIssues(reports.head.site.alerts);
      const baseIssues = parseDastIssues(reports.base.site.alerts);
      const filterKey = 'pluginid';
      const newIssues = filterByKey(headIssues, baseIssues, filterKey);
      const resolvedIssues = filterByKey(baseIssues, headIssues, filterKey);

      state.dast.newIssues = newIssues;
      state.dast.resolvedIssues = resolvedIssues;
      state.dast.isLoading = false;
      state.summaryCounts.added += newIssues.length;
      state.summaryCounts.fixed += resolvedIssues.length;
    } else if (reports.head && !reports.base) {
      const newIssues = parseDastIssues(reports.head.site.alerts);

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
      const parsedHead = parseSastIssues(reports.head, state.blobPath.head);
      const parsedBase = parseSastIssues(reports.base, state.blobPath.base);

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
      const newIssues = parseSastIssues(reports.head, state.blobPath.head);
      state.dependencyScanning.newIssues = newIssues;
      state.dependencyScanning.isLoading = false;
      state.summaryCounts.added += newIssues.length;
    }
  },

  [types.RECEIVE_DEPENDENCY_SCANNING_ERROR](state) {
    state.dependencyScanning.isLoading = false;
    state.dependencyScanning.hasError = true;
  },
};
