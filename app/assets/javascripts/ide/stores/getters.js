import minimatch from 'minimatch';
import { getChangesCountForFiles, filePathMatches } from './utils';
import { activityBarViews, packageJsonPath, encodingTypes } from '../constants';

export const activeFile = state => state.openFiles.find(file => file.active) || null;

export const addedFiles = state => state.changedFiles.filter(f => f.tempFile);

export const modifiedFiles = state => state.changedFiles.filter(f => !f.tempFile);

export const projectsWithTrees = state =>
  Object.keys(state.projects).map(projectId => {
    const project = state.projects[projectId];

    return {
      ...project,
      branches: Object.keys(project.branches).map(branchId => {
        const branch = project.branches[branchId];

        return {
          ...branch,
          tree: state.trees[branch.treeId],
        };
      }),
    };
  });

export const currentMergeRequest = state => {
  if (state.projects[state.currentProjectId]) {
    return state.projects[state.currentProjectId].mergeRequests[state.currentMergeRequestId];
  }
  return null;
};

export const currentProject = state => state.projects[state.currentProjectId];

export const currentTree = state =>
  state.trees[`${state.currentProjectId}/${state.currentBranchId}`];

export const hasChanges = state => !!state.changedFiles.length || !!state.stagedFiles.length;

export const hasMergeRequest = state => !!state.currentMergeRequestId;

export const allBlobs = state =>
  Object.keys(state.entries)
    .reduce((acc, key) => {
      const entry = state.entries[key];

      if (entry.type === 'blob') {
        acc.push(entry);
      }

      return acc;
    }, [])
    .sort((a, b) => b.lastOpenedAt - a.lastOpenedAt);

export const getChangedFile = state => path => state.changedFiles.find(f => f.path === path);
export const getStagedFile = state => path => state.stagedFiles.find(f => f.path === path);

export const lastOpenedFile = state =>
  [...state.changedFiles, ...state.stagedFiles].sort((a, b) => b.lastOpenedAt - a.lastOpenedAt)[0];

export const isEditModeActive = state => state.currentActivityView === activityBarViews.edit;
export const isCommitModeActive = state => state.currentActivityView === activityBarViews.commit;
export const isReviewModeActive = state => state.currentActivityView === activityBarViews.review;

export const someUncommitedChanges = state =>
  !!(state.changedFiles.length || state.stagedFiles.length);

export const getChangesInFolder = state => path => {
  const changedFilesCount = state.changedFiles.filter(f => filePathMatches(f.path, path)).length;
  const stagedFilesCount = state.stagedFiles.filter(
    f => filePathMatches(f.path, path) && !getChangedFile(state)(f.path),
  ).length;

  return changedFilesCount + stagedFilesCount;
};

export const getUnstagedFilesCountForPath = state => path =>
  getChangesCountForFiles(state.changedFiles, path);

export const getStagedFilesCountForPath = state => path =>
  getChangesCountForFiles(state.stagedFiles, path);

export const lastCommit = (state, getters) => {
  const branch = getters.currentProject && getters.currentBranch;

  return branch ? branch.commit : null;
};

export const currentBranch = (state, getters) =>
  getters.currentProject && getters.currentProject.branches[state.currentBranchId];

export const packageJson = state => state.entries[packageJsonPath];

export const parsedGitattributes = state => {
  const gitattributes = state.entries['.gitattributes'];

  if (!gitattributes || (gitattributes && !gitattributes.raw)) return {};

  const extensionRegex = new RegExp('(.*)\\s');
  const encodingRegex = new RegExp('(-text|text|binary)');

  return (gitattributes.content || gitattributes.raw).split('\n').reduce((acc, line) => {
    const pathMatch = line.match(extensionRegex);
    const encodingMatch = line.match(encodingRegex);

    if (!pathMatch || !encodingMatch) return acc;

    const encoding =
      encodingMatch.pop() === encodingTypes.text ? encodingTypes.text : encodingTypes.binary;

    return {
      ...acc,
      [pathMatch[0].trim()]: {
        encoding,
      },
    };
  }, {});
};

export const isFileBinary = (state, getters) => file =>
  Object.keys(getters.parsedGitattributes).reduce((acc, key) => {
    if (minimatch(file.name, key)) {
      return getters.parsedGitattributes[key].encoding === encodingTypes.binary;
    }

    return acc;
  }, false) || file.binary;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
