/* eslint-disable comma-dangle, object-shorthand, no-param-reassign, camelcase, no-nested-ternary, no-continue, max-len */

import $ from 'jquery';
import Vue from 'vue';
import Cookies from 'js-cookie';

((global) => {
  global.mergeConflicts = global.mergeConflicts || {};

  const diffViewType = Cookies.get('diff_view');
  const HEAD_HEADER_TEXT = 'HEAD//our changes';
  const ORIGIN_HEADER_TEXT = 'origin//their changes';
  const HEAD_BUTTON_TITLE = 'Use ours';
  const ORIGIN_BUTTON_TITLE = 'Use theirs';
  const INTERACTIVE_RESOLVE_MODE = 'interactive';
  const EDIT_RESOLVE_MODE = 'edit';
  const DEFAULT_RESOLVE_MODE = INTERACTIVE_RESOLVE_MODE;
  const VIEW_TYPES = {
    INLINE: 'inline',
    PARALLEL: 'parallel'
  };
  const CONFLICT_TYPES = {
    TEXT: 'text',
    TEXT_EDITOR: 'text-editor'
  };

  global.mergeConflicts.mergeConflictsStore = {
    state: {
      isLoading: true,
      hasError: false,
      isSubmitting: false,
      isParallel: diffViewType === VIEW_TYPES.PARALLEL,
      diffViewType: diffViewType,
      conflictsData: {}
    },

    setConflictsData(data) {
      this.decorateFiles(data.files);

      this.state.conflictsData = {
        files: data.files,
        commitMessage: data.commit_message,
        sourceBranch: data.source_branch,
        targetBranch: data.target_branch,
        shortCommitSha: data.commit_sha.slice(0, 7),
      };
    },

    decorateFiles(files) {
      files.forEach((file) => {
        file.content = '';
        file.resolutionData = {};
        file.promptDiscardConfirmation = false;
        file.resolveMode = DEFAULT_RESOLVE_MODE;
        file.filePath = this.getFilePath(file);
        file.iconClass = `fa-${file.blob_icon}`;
        file.blobPath = file.blob_path;

        if (file.type === CONFLICT_TYPES.TEXT) {
          file.showEditor = false;
          file.loadEditor = false;

          this.setInlineLine(file);
          this.setParallelLine(file);
        } else if (file.type === CONFLICT_TYPES.TEXT_EDITOR) {
          file.showEditor = true;
          file.loadEditor = true;
        }
      });
    },

    setInlineLine(file) {
      file.inlineLines = [];

      file.sections.forEach((section) => {
        let currentLineType = 'new';
        const { conflict, lines, id } = section;

        if (conflict) {
          file.inlineLines.push(this.getHeadHeaderLine(id));
        }

        lines.forEach((line) => {
          const { type } = line;

          if ((type === 'new' || type === 'old') && currentLineType !== type) {
            currentLineType = type;
            file.inlineLines.push({ lineType: 'emptyLine', richText: '' });
          }

          this.decorateLineForInlineView(line, id, conflict);
          file.inlineLines.push(line);
        });

        if (conflict) {
          file.inlineLines.push(this.getOriginHeaderLine(id));
        }
      });
    },

    setParallelLine(file) {
      file.parallelLines = [];
      const linesObj = { left: [], right: [] };

      file.sections.forEach((section) => {
        const { conflict, lines, id } = section;

        if (conflict) {
          linesObj.left.push(this.getOriginHeaderLine(id));
          linesObj.right.push(this.getHeadHeaderLine(id));
        }

        lines.forEach((line) => {
          const { type } = line;

          if (conflict) {
            if (type === 'old') {
              linesObj.left.push(this.getLineForParallelView(line, id, 'conflict'));
            } else if (type === 'new') {
              linesObj.right.push(this.getLineForParallelView(line, id, 'conflict', true));
            }
          } else {
            const lineType = type || 'context';

            linesObj.left.push(this.getLineForParallelView(line, id, lineType));
            linesObj.right.push(this.getLineForParallelView(line, id, lineType, true));
          }
        });

        this.checkLineLengths(linesObj);
      });

      for (let i = 0, len = linesObj.left.length; i < len; i += 1) {
        file.parallelLines.push([
          linesObj.right[i],
          linesObj.left[i]
        ]);
      }
    },

    setLoadingState(state) {
      this.state.isLoading = state;
    },

    setErrorState(state) {
      this.state.hasError = state;
    },

    setFailedRequest(message) {
      this.state.hasError = true;
      this.state.conflictsData.errorMessage = message;
    },

    getConflictsCount() {
      if (!this.state.conflictsData.files.length) {
        return 0;
      }

      const files = this.state.conflictsData.files;
      let count = 0;

      files.forEach((file) => {
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
      const count = this.getConflictsCount();
      const text = count > 1 ? 'conflicts' : 'conflict';

      return `${count} ${text}`;
    },

    setViewType(viewType) {
      this.state.diffView = viewType;
      this.state.isParallel = viewType === VIEW_TYPES.PARALLEL;

      Cookies.set('diff_view', viewType);
    },

    getHeadHeaderLine(id) {
      return {
        id: id,
        richText: HEAD_HEADER_TEXT,
        buttonTitle: HEAD_BUTTON_TITLE,
        type: 'new',
        section: 'head',
        isHeader: true,
        isHead: true,
        isSelected: false,
        isUnselected: false
      };
    },

    decorateLineForInlineView(line, id, conflict) {
      const { type } = line;
      line.id = id;
      line.hasConflict = conflict;
      line.isHead = type === 'new';
      line.isOrigin = type === 'old';
      line.hasMatch = type === 'match';
      line.richText = line.rich_text;
      line.isSelected = false;
      line.isUnselected = false;
    },

    getLineForParallelView(line, id, lineType, isHead) {
      const { old_line, new_line, rich_text } = line;
      const hasConflict = lineType === 'conflict';

      return {
        id,
        lineType,
        hasConflict,
        isHead: hasConflict && isHead,
        isOrigin: hasConflict && !isHead,
        hasMatch: lineType === 'match',
        lineNumber: isHead ? new_line : old_line,
        section: isHead ? 'head' : 'origin',
        richText: rich_text,
        isSelected: false,
        isUnselected: false
      };
    },

    getOriginHeaderLine(id) {
      return {
        id: id,
        richText: ORIGIN_HEADER_TEXT,
        buttonTitle: ORIGIN_BUTTON_TITLE,
        type: 'old',
        section: 'origin',
        isHeader: true,
        isOrigin: true,
        isSelected: false,
        isUnselected: false
      };
    },

    getFilePath(file) {
      const { old_path, new_path } = file;
      return old_path === new_path ? new_path : `${old_path} → ${new_path}`;
    },

    checkLineLengths(linesObj) {
      const { left, right } = linesObj;

      if (left.length !== right.length) {
        if (left.length > right.length) {
          const diff = left.length - right.length;
          for (let i = 0; i < diff; i += 1) {
            right.push({ lineType: 'emptyLine', richText: '' });
          }
        } else {
          const diff = right.length - left.length;
          for (let i = 0; i < diff; i += 1) {
            left.push({ lineType: 'emptyLine', richText: '' });
          }
        }
      }
    },

    setPromptConfirmationState(file, state) {
      file.promptDiscardConfirmation = state;
    },

    setFileResolveMode(file, mode) {
      if (mode === INTERACTIVE_RESOLVE_MODE) {
        file.showEditor = false;
      } else if (mode === EDIT_RESOLVE_MODE) {
        // Restore Interactive mode when switching to Edit mode
        file.showEditor = true;
        file.loadEditor = true;
        file.resolutionData = {};

        this.restoreFileLinesState(file);
      }

      file.resolveMode = mode;
    },

    restoreFileLinesState(file) {
      file.inlineLines.forEach((line) => {
        if (line.hasConflict || line.isHeader) {
          line.isSelected = false;
          line.isUnselected = false;
        }
      });

      file.parallelLines.forEach((lines) => {
        const left = lines[0];
        const right = lines[1];
        const isLeftMatch = left.hasConflict || left.isHeader;
        const isRightMatch = right.hasConflict || right.isHeader;

        if (isLeftMatch || isRightMatch) {
          left.isSelected = false;
          left.isUnselected = false;
          right.isSelected = false;
          right.isUnselected = false;
        }
      });
    },

    isReadyToCommit() {
      const files = this.state.conflictsData.files;
      const hasCommitMessage = $.trim(this.state.conflictsData.commitMessage).length;
      let unresolved = 0;

      for (let i = 0, l = files.length; i < l; i += 1) {
        const file = files[i];

        if (file.resolveMode === INTERACTIVE_RESOLVE_MODE) {
          let numberConflicts = 0;
          const resolvedConflicts = Object.keys(file.resolutionData).length;

          // We only check for conflicts type 'text'
          // since conflicts `text_editor` can´t be resolved in interactive mode
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
          // Unlikely to happen since switching to Edit mode saves content automatically.
          // Checking anyway in case the save strategy changes in the future
          if (!file.content) {
            unresolved += 1;
            continue;
          }
        }
      }

      return !this.state.isSubmitting && hasCommitMessage && !unresolved;
    },

    getCommitButtonText() {
      const initial = 'Commit conflict resolution';
      const inProgress = 'Committing...';

      return this.state ? this.state.isSubmitting ? inProgress : initial : initial;
    },

    getCommitData() {
      let commitData = {};

      commitData = {
        commit_message: this.state.conflictsData.commitMessage,
        files: []
      };

      this.state.conflictsData.files.forEach((file) => {
        const addFile = {
          old_path: file.old_path,
          new_path: file.new_path
        };

        if (file.type === CONFLICT_TYPES.TEXT) {
          // Submit only one data for type of editing
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

    handleSelected(file, sectionId, selection) {
      Vue.set(file.resolutionData, sectionId, selection);

      file.inlineLines.forEach((line) => {
        if (line.id === sectionId && (line.hasConflict || line.isHeader)) {
          this.markLine(line, selection);
        }
      });

      file.parallelLines.forEach((lines) => {
        const left = lines[0];
        const right = lines[1];
        const hasSameId = right.id === sectionId || left.id === sectionId;
        const isLeftMatch = left.hasConflict || left.isHeader;
        const isRightMatch = right.hasConflict || right.isHeader;

        if (hasSameId && (isLeftMatch || isRightMatch)) {
          this.markLine(left, selection);
          this.markLine(right, selection);
        }
      });
    },

    markLine(line, selection) {
      if (selection === 'head' && line.isHead) {
        line.isSelected = true;
        line.isUnselected = false;
      } else if (selection === 'origin' && line.isOrigin) {
        line.isSelected = true;
        line.isUnselected = false;
      } else {
        line.isSelected = false;
        line.isUnselected = true;
      }
    },

    setSubmitState(state) {
      this.state.isSubmitting = state;
    },

    fileTextTypePresent() {
      return this.state.conflictsData.files.some(f => f.type === CONFLICT_TYPES.TEXT);
    }
  };
})(window.gl || (window.gl = {}));
