import { defineStore } from 'pinia';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import {
  CONFLICT_TYPES,
  EDIT_RESOLVE_MODE,
  INTERACTIVE_RESOLVE_MODE,
  VIEW_TYPES,
} from '../constants';
import { decorateFiles, markLine, restoreFileLinesState } from '../utils';

const diffViewType = getCookie('diff_view');

export const useMergeConflicts = defineStore('mergeConflicts', {
  state: () => ({
    isLoading: true,
    hasError: false,
    isSubmitting: false,
    isParallel: diffViewType === VIEW_TYPES.PARALLEL,
    diffViewType,
    // Initialize `files` and `commitMessage` so getters that iterate files
    // or call `.trim()` on commitMessage don't throw when @pinia/testing
    // eagerly evaluates computed getters at store-creation time.
    conflictsData: { files: [], commitMessage: '' },
  }),
  getters: {
    getConflictsCount() {
      if (!this.conflictsData.files?.length) {
        return 0;
      }

      let count = 0;

      this.conflictsData.files.forEach((file) => {
        if (file.type === CONFLICT_TYPES.TEXT) {
          file.sections.forEach((section) => {
            if (section.conflict) {
              count += 1;
            }
          });
        } else {
          count += 1;
        }
      });

      return count;
    },
    getConflictsCountText() {
      const count = this.getConflictsCount;
      const text = count > 1 ? s__('MergeConflict|conflicts') : s__('MergeConflict|conflict');

      return `${count} ${text}`;
    },
    isReadyToCommit() {
      const { files } = this.conflictsData;
      const hasCommitMessage = this.conflictsData.commitMessage.trim().length;
      let unresolved = 0;

      for (let i = 0, l = files.length; i < l; i += 1) {
        const file = files[i];

        if (file.resolveMode === INTERACTIVE_RESOLVE_MODE) {
          let numberConflicts = 0;
          const resolvedConflicts = Object.keys(file.resolutionData).length;

          if (file.type === CONFLICT_TYPES.TEXT) {
            for (let j = 0, k = file.sections.length; j < k; j += 1) {
              if (file.sections[j].conflict) {
                numberConflicts += 1;
              }
            }

            if (resolvedConflicts !== numberConflicts) {
              unresolved += 1;
            }
          }
        } else if (file.resolveMode === EDIT_RESOLVE_MODE) {
          if (!file.content) {
            unresolved += 1;
            continue;
          }
        }
      }

      return Boolean(!this.isSubmitting && hasCommitMessage && !unresolved);
    },
    getCommitButtonText() {
      const initial = s__('MergeConflict|Commit to source branch');
      const inProgress = s__('MergeConflict|Committing…');

      return this.isSubmitting ? inProgress : initial;
    },
    getCommitData() {
      const commitData = {
        commit_message: this.conflictsData.commitMessage,
        files: [],
      };

      this.conflictsData.files.forEach((file) => {
        const addFile = {
          old_path: file.old_path,
          new_path: file.new_path,
        };

        if (file.type === CONFLICT_TYPES.TEXT) {
          if (file.resolveMode === INTERACTIVE_RESOLVE_MODE) {
            addFile.sections = file.resolutionData;
          } else if (file.resolveMode === EDIT_RESOLVE_MODE) {
            addFile.content = file.content;
          }
        } else if (file.type === CONFLICT_TYPES.TEXT_EDITOR) {
          addFile.content = file.content;
        }

        commitData.files.push(addFile);
      });

      return commitData;
    },
    fileTextTypePresent() {
      return this.conflictsData?.files.some((f) => f.type === CONFLICT_TYPES.TEXT);
    },
    getFileIndex() {
      return ({ blobPath }) => this.conflictsData.files.findIndex((f) => f.blobPath === blobPath);
    },
  },
  actions: {
    async fetchConflictsData(conflictsPath) {
      this.isLoading = true;
      try {
        const { data } = await axios.get(conflictsPath);
        if (data.type === 'error') {
          this.hasError = true;
          this.conflictsData.errorMessage = data.message;
        } else {
          this.setConflictsData(data);
        }
      } catch {
        this.hasError = true;
        this.conflictsData.errorMessage = undefined;
      } finally {
        this.isLoading = false;
      }
    },
    setConflictsData(data) {
      const files = decorateFiles(data);
      this.conflictsData = {
        files,
        commitMessage: data.commit_message,
        sourceBranch: data.source_branch,
        targetBranch: data.target_branch,
        shortCommitSha: data.commit_sha?.slice(0, 7),
      };
    },
    async submitResolvedConflicts(resolveConflictsPath) {
      this.isSubmitting = true;
      try {
        const { data } = await axios.post(resolveConflictsPath, this.getCommitData);
        window.location.assign(data.redirect_to);
      } catch {
        this.isSubmitting = false;
        createAlert({
          message: __('Failed to save merge conflict resolutions. Please try again.'),
        });
      }
    },
    setLoadingState(isLoading) {
      this.isLoading = isLoading;
    },
    setErrorState(hasError) {
      this.hasError = hasError;
    },
    setFailedRequest(message) {
      this.hasError = true;
      this.conflictsData.errorMessage = message;
    },
    setViewType(viewType) {
      // NOTE: the original mutation sets `diffView`, not `diffViewType`.
      // Preserving this inconsistency for behavior parity with Vuex.
      this.diffView = viewType;
      this.isParallel = viewType === VIEW_TYPES.PARALLEL;
      setCookie('diff_view', viewType);
    },
    setSubmitState(isSubmitting) {
      this.isSubmitting = isSubmitting;
    },
    updateCommitMessage(commitMessage) {
      this.conflictsData = { ...this.conflictsData, commitMessage };
    },
    setFileResolveMode({ file, mode }) {
      const index = this.getFileIndex(file);
      const updated = { ...this.conflictsData.files[index] };
      if (mode === INTERACTIVE_RESOLVE_MODE) {
        updated.showEditor = false;
      } else if (mode === EDIT_RESOLVE_MODE) {
        updated.showEditor = true;
        updated.loadEditor = true;
        updated.resolutionData = {};

        const { inlineLines, parallelLines } = restoreFileLinesState(updated);
        updated.parallelLines = parallelLines;
        updated.inlineLines = inlineLines;
      }
      updated.resolveMode = mode;
      this.conflictsData.files.splice(index, 1, updated);
    },
    setPromptConfirmationState({ file, promptDiscardConfirmation }) {
      const index = this.getFileIndex(file);
      const updated = { ...this.conflictsData.files[index], promptDiscardConfirmation };
      this.conflictsData.files.splice(index, 1, updated);
    },
    handleSelected({ file, line: { id, section } }) {
      const index = this.getFileIndex(file);
      const updated = { ...this.conflictsData.files[index] };
      updated.resolutionData = { ...updated.resolutionData, [id]: section };

      updated.inlineLines = file.inlineLines.map((line) => {
        if (id === line.id && (line.hasConflict || line.isHeader)) {
          return markLine(line, section);
        }
        return line;
      });

      updated.parallelLines = file.parallelLines.map((lines) => {
        let left = { ...lines[0] };
        let right = { ...lines[1] };
        const hasSameId = right.id === id || left.id === id;
        const isLeftMatch = left.hasConflict || left.isHeader;
        const isRightMatch = right.hasConflict || right.isHeader;

        if (hasSameId && (isLeftMatch || isRightMatch)) {
          left = markLine(left, section);
          right = markLine(right, section);
        }
        return [left, right];
      });

      this.conflictsData.files.splice(index, 1, updated);
    },
    updateFile(file) {
      const index = this.getFileIndex(file);
      this.conflictsData.files.splice(index, 1, file);
    },
  },
});
