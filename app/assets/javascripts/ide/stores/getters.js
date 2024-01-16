import Api from '~/api';
import { addNumericSuffix } from '~/ide/utils';
import {
  leftSidebarViews,
  DEFAULT_PERMISSIONS,
  PERMISSION_READ_MR,
  PERMISSION_CREATE_MR,
  PERMISSION_PUSH_CODE,
  PUSH_RULE_REJECT_UNSIGNED_COMMITS,
} from '../constants';
import {
  MSG_CANNOT_PUSH_CODE,
  MSG_CANNOT_PUSH_CODE_SHOULD_FORK,
  MSG_CANNOT_PUSH_CODE_GO_TO_FORK,
  MSG_CANNOT_PUSH_UNSIGNED,
  MSG_CANNOT_PUSH_UNSIGNED_SHORT,
  MSG_FORK,
  MSG_GO_TO_FORK,
} from '../messages';
import { getChangesCountForFiles, filePathMatches } from './utils';

const getCannotPushCodeViewModel = (state) => {
  const { ide_path: idePath, fork_path: forkPath } = state.links.forkInfo || {};

  if (idePath) {
    return {
      message: MSG_CANNOT_PUSH_CODE_GO_TO_FORK,
      action: {
        href: idePath,
        text: MSG_GO_TO_FORK,
      },
    };
  }
  if (forkPath) {
    return {
      message: MSG_CANNOT_PUSH_CODE_SHOULD_FORK,
      action: {
        href: forkPath,
        isForm: true,
        text: MSG_FORK,
      },
    };
  }

  return {
    message: MSG_CANNOT_PUSH_CODE,
  };
};

export const activeFile = (state) => state.openFiles.find((file) => file.active) || null;

export const addedFiles = (state) => state.changedFiles.filter((f) => f.tempFile);

export const modifiedFiles = (state) => state.changedFiles.filter((f) => !f.tempFile);

export const projectsWithTrees = (state) =>
  Object.keys(state.projects).map((projectId) => {
    const project = state.projects[projectId];

    return {
      ...project,
      branches: Object.keys(project.branches).map((branchId) => {
        const branch = project.branches[branchId];

        return {
          ...branch,
          tree: state.trees[branch.treeId],
        };
      }),
    };
  });

export const currentMergeRequest = (state) => {
  if (
    state.projects[state.currentProjectId] &&
    state.projects[state.currentProjectId].mergeRequests
  ) {
    return state.projects[state.currentProjectId].mergeRequests[state.currentMergeRequestId];
  }
  return null;
};

export const findProject = (state) => (projectId) => state.projects[projectId];

export const currentProject = (state, getters) => getters.findProject(state.currentProjectId);

export const emptyRepo = (state) =>
  state.projects[state.currentProjectId] && state.projects[state.currentProjectId].empty_repo;

export const currentTree = (state) =>
  state.trees[`${state.currentProjectId}/${state.currentBranchId}`];

export const hasMergeRequest = (state) => Boolean(state.currentMergeRequestId);

export const allBlobs = (state) =>
  Object.keys(state.entries)
    .reduce((acc, key) => {
      const entry = state.entries[key];

      if (entry.type === 'blob') {
        acc.push(entry);
      }

      return acc;
    }, [])
    .sort((a, b) => b.lastOpenedAt - a.lastOpenedAt);

export const getChangedFile = (state) => (path) => state.changedFiles.find((f) => f.path === path);
export const getStagedFile = (state) => (path) => state.stagedFiles.find((f) => f.path === path);
export const getOpenFile = (state) => (path) => state.openFiles.find((f) => f.path === path);

export const lastOpenedFile = (state) =>
  [...state.changedFiles, ...state.stagedFiles].sort((a, b) => b.lastOpenedAt - a.lastOpenedAt)[0];

export const isEditModeActive = (state) => state.currentActivityView === leftSidebarViews.edit.name;
export const isCommitModeActive = (state) =>
  state.currentActivityView === leftSidebarViews.commit.name;
export const isReviewModeActive = (state) =>
  state.currentActivityView === leftSidebarViews.review.name;

export const someUncommittedChanges = (state) =>
  Boolean(state.changedFiles.length || state.stagedFiles.length);

export const getChangesInFolder = (state) => (path) => {
  const changedFilesCount = state.changedFiles.filter((f) => filePathMatches(f.path, path)).length;
  const stagedFilesCount = state.stagedFiles.filter(
    (f) => filePathMatches(f.path, path) && !getChangedFile(state)(f.path),
  ).length;

  return changedFilesCount + stagedFilesCount;
};

export const getUnstagedFilesCountForPath = (state) => (path) =>
  getChangesCountForFiles(state.changedFiles, path);

export const getStagedFilesCountForPath = (state) => (path) =>
  getChangesCountForFiles(state.stagedFiles, path);

export const lastCommit = (state, getters) => {
  const branch = getters.currentProject && getters.currentBranch;

  return branch ? branch.commit : null;
};

export const findBranch = (state, getters) => (projectId, branchId) => {
  const project = getters.findProject(projectId);

  return project && project.branches[branchId];
};

export const currentBranch = (state, getters) =>
  getters.findBranch(state.currentProjectId, state.currentBranchId);

export const branchName = (_state, getters) => getters.currentBranch && getters.currentBranch.name;

export const isOnDefaultBranch = (_state, getters) =>
  getters.currentProject && getters.currentProject.default_branch === getters.branchName;

export const canPushToBranch = (_state, getters) => {
  return Boolean(getters.currentBranch ? getters.currentBranch.can_push : getters.canPushCode);
};

export const isFileDeletedAndReadded = (state, getters) => (path) => {
  const stagedFile = getters.getStagedFile(path);
  const file = state.entries[path];
  return Boolean(stagedFile && stagedFile.deleted && file.tempFile);
};

// checks if any diff exists in the staged or unstaged changes for this path
export const getDiffInfo = (state, getters) => (path) => {
  const stagedFile = getters.getStagedFile(path);
  const file = state.entries[path];
  const renamed = file.prevPath ? file.path !== file.prevPath : false;
  const deletedAndReadded = getters.isFileDeletedAndReadded(path);
  const deleted = deletedAndReadded ? false : file.deleted;
  const tempFile = deletedAndReadded ? false : file.tempFile;
  const changed = file.content !== (deletedAndReadded ? stagedFile.raw : file.raw);

  return {
    exists: changed || renamed || deleted || tempFile,
    changed,
    renamed,
    deleted,
    tempFile,
  };
};

export const findProjectPermissions = (state, getters) => (projectId) =>
  getters.findProject(projectId)?.userPermissions || DEFAULT_PERMISSIONS;

export const findPushRules = (state, getters) => (projectId) =>
  getters.findProject(projectId)?.pushRules || {};

export const canReadMergeRequests = (state, getters) =>
  Boolean(getters.findProjectPermissions(state.currentProjectId)[PERMISSION_READ_MR]);

export const canCreateMergeRequests = (state, getters) =>
  Boolean(getters.findProjectPermissions(state.currentProjectId)[PERMISSION_CREATE_MR]);

/**
 * Returns an object with `isAllowed` and `message` based on why the user cant push code
 */
export const canPushCodeStatus = (state, getters) => {
  const canPushCode = getters.findProjectPermissions(state.currentProjectId)[PERMISSION_PUSH_CODE];
  const rejectUnsignedCommits = getters.findPushRules(state.currentProjectId)[
    PUSH_RULE_REJECT_UNSIGNED_COMMITS
  ];

  if (window.gon?.features?.rejectUnsignedCommitsByGitlab && rejectUnsignedCommits) {
    return {
      isAllowed: false,
      message: MSG_CANNOT_PUSH_UNSIGNED,
      messageShort: MSG_CANNOT_PUSH_UNSIGNED_SHORT,
    };
  }
  if (!canPushCode) {
    return {
      isAllowed: false,
      messageShort: MSG_CANNOT_PUSH_CODE,
      ...getCannotPushCodeViewModel(state),
    };
  }

  return {
    isAllowed: true,
    message: '',
    messageShort: '',
  };
};

export const canPushCode = (state, getters) => getters.canPushCodeStatus.isAllowed;

export const entryExists = (state) => (path) =>
  Boolean(state.entries[path] && !state.entries[path].deleted);

export const getAvailableFileName = (state, getters) => (path) => {
  let newPath = path;

  while (getters.entryExists(newPath)) {
    newPath = addNumericSuffix(newPath);
  }

  return newPath;
};

export const getUrlForPath = (state) => (path) =>
  `/project/${state.currentProjectId}/tree/${state.currentBranchId}/-/${path}/`;

export const getJsonSchemaForPath = (state, getters) => (path) => {
  const [namespace, ...project] = state.currentProjectId.split('/');
  return {
    uri:
      // eslint-disable-next-line no-restricted-globals
      location.origin +
      Api.buildUrl(Api.projectFileSchemaPath)
        .replace(':namespace_path', namespace)
        .replace(':project_path', project.join('/'))
        .replace(':ref', getters.currentBranch?.commit.id || state.currentBranchId)
        .replace(':filename', path),
    fileMatch: [`*${path}`],
  };
};
