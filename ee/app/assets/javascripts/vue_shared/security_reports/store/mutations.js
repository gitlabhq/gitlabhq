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
    Object.assign(state.blobPath, { head: path });
  },

  [types.SET_BASE_BLOB_PATH](state, path) {
    Object.assign(state.blobPath, { base: path });
  },

  // SAST
  [types.SET_SAST_HEAD_PATH](state, path) {
    Object.assign(state.sast.paths, { head: path });
  },

  [types.SET_SAST_BASE_PATH](state, path) {
    Object.assign(state.sast.paths, { base: path });
  },

  [types.REQUEST_SAST_REPORTS](state) {
    Object.assign(state.sast, { isLoading: true });
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

      Object.assign(state, {
        sast: {
          ...state.sast,
          newIssues,
          resolvedIssues,
          allIssues,
          isLoading: false,
        },
        summaryCounts: {
          added: state.summaryCounts.added + newIssues.length,
          fixed: state.summaryCounts.fixed + resolvedIssues.length,
        },
      });
    } else if (reports.head && !reports.base) {
      const newIssues = parseSastIssues(reports.head, state.blobPath.head);

      Object.assign(state.sast, {
        newIssues,
        isLoading: false,
      });
    }
  },

  [types.RECEIVE_SAST_REPORTS_ERROR](state) {
    Object.assign(state.sast, {
      isLoading: false,
      hasError: true,
    });
  },

  // SAST CONTAINER
  [types.SET_SAST_CONTAINER_HEAD_PATH](state, path) {
    Object.assign(state.sastContainer.paths, { head: path });
  },

  [types.SET_SAST_CONTAINER_BASE_PATH](state, path) {
    Object.assign(state.sastContainer.paths, { base: path });
  },

  [types.REQUEST_SAST_CONTAINER_REPORTS](state) {
    Object.assign(state.sastContainer, { isLoading: true });
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

      Object.assign(state, {
        sastContainer: {
          ...state.sastContainer,
          isLoading: false,
          newIssues,
          resolvedIssues,
        },
        summaryCounts: {
          added: state.summaryCounts.added + newIssues.length,
          fixed: state.summaryCounts.fixed + resolvedIssues.length,
        },
      });
    } else if (reports.head && !reports.base) {
      Object.assign(state.sastContainer, {
        isLoading: false,
        newIssues: getUnapprovedVulnerabilities(
          parseSastContainer(reports.head.vulnerabilities),
          reports.head.unapproved,
        ),
      });
    }
  },

  [types.RECEIVE_SAST_CONTAINER_ERROR](state) {
    Object.assign(state.sastContainer, {
      isLoading: false,
      hasError: true,
    });
  },

  // DAST

  [types.SET_DAST_HEAD_PATH](state, path) {
    Object.assign(state.dast.paths, { head: path });
  },

  [types.SET_DAST_BASE_PATH](state, path) {
    Object.assign(state.dast.paths, { base: path });
  },

  [types.REQUEST_DAST_REPORTS](state) {
    Object.assign(state.dast, { isLoading: true });
  },

  [types.RECEIVE_DAST_REPORTS](state, reports) {
    if (reports.head && reports.base) {
      const headIssues = parseDastIssues(reports.head.site.alerts);
      const baseIssues = parseDastIssues(reports.base.site.alerts);
      const filterKey = 'pluginid';
      const newIssues = filterByKey(headIssues, baseIssues, filterKey);
      const resolvedIssues = filterByKey(baseIssues, headIssues, filterKey);

      Object.assign(state, {
        dast: {
          ...state.dast,
          isLoading: false,
          newIssues,
          resolvedIssues,
        },
        summaryCounts: {
          added: state.summaryCounts.added + newIssues.length,
          fixed: state.summaryCounts.fixed + resolvedIssues.length,
        },
      });
    } else if (reports.head && !reports.base) {
      Object.assign(state.dast, {
        isLoading: false,
        newIssues: parseDastIssues(reports.head.site.alerts),
      });
    }
  },

  [types.RECEIVE_DAST_ERROR](state) {
    Object.assign(state.dast, {
      isLoading: false,
      hasError: true,
    });
  },

  // DEPENDECY SCANNING

  [types.SET_DEPENDENCY_SCANNING_HEAD_PATH](state, path) {
    Object.assign(state.dependencyScanning.paths, { head: path });
  },

  [types.SET_DEPENDENCY_SCANNING_BASE_PATH](state, path) {
    Object.assign(state.dependencyScanning.paths, { base: path });
  },

  [types.REQUEST_DEPENDENCY_SCANNING_REPORTS](state) {
    Object.assign(state.dependencyScanning, { isLoading: true });
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

      Object.assign(state, {
        dependencyScanning: {
          ...state.dependencyScanning,
          newIssues,
          resolvedIssues,
          allIssues,
          isLoading: false,
        },
        summaryCounts: {
          added: state.summaryCounts.added + newIssues.length,
          fixed: state.summaryCounts.fixed + resolvedIssues.length,
        },
      });
    } else {
      Object.assign(state.dependencyScanning, {
        newIssues: parseSastIssues(reports.head, state.blobPath.head),
        isLoading: false,
      });
    }
  },

  [types.RECEIVE_DEPENDENCY_SCANNING_ERROR](state) {
    Object.assign(state.dependencyScanning, {
      isLoading: false,
      hasError: true,
    });
  },
};
