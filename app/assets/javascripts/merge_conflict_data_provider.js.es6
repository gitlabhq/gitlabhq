const HEAD_HEADER_TEXT    = 'HEAD//our changes';
const ORIGIN_HEADER_TEXT  = 'origin//their changes';
const HEAD_BUTTON_TITLE   = 'Use ours';
const ORIGIN_BUTTON_TITLE = 'Use theirs';
const INTERACTIVE_RESOLVE_MODE = 'interactive';
const EDIT_RESOLVE_MODE = 'edit';
const DEFAULT_RESOLVE_MODE = INTERACTIVE_RESOLVE_MODE;

class MergeConflictDataProvider {

  getInitialData() {
    // TODO: remove reliance on jQuery and DOM state introspection
    const diffViewType = $.cookie('diff_view');
    const fixedLayout = $('.content-wrapper .container-fluid').hasClass('container-limited');

    return {
      isLoading      : true,
      hasError       : false,
      isParallel     : diffViewType === 'parallel',
      diffViewType   : diffViewType,
      fixedLayout    : fixedLayout,
      isSubmitting   : false,
      conflictsData  : {}
    }
  }


  decorateData(vueInstance, data) {
    this.vueInstance = vueInstance;

    if (data.type === 'error') {
      vueInstance.hasError = true;
      data.errorMessage = data.message;
    }
    else {
      data.shortCommitSha = data.commit_sha.slice(0, 7);
      data.commitMessage  = data.commit_message;

      this.decorateFiles(data);
      this.setParallelLines(data);
      this.setInlineLines(data);
    }

    vueInstance.conflictsData = data;
    vueInstance.isSubmitting = false;

    const conflictsText = this.getConflictsCount() > 1 ? 'conflicts' : 'conflict';
    vueInstance.conflictsData.conflictsText = conflictsText;
  }

  decorateFiles(data) {
    data.files.forEach((file) => {
      file.content = '';
      file.resolutionData = {};
      file.promptDiscardConfirmation = false;
      file.resolveMode = DEFAULT_RESOLVE_MODE;
    });
  }


  setParallelLines(data) {
    data.files.forEach( (file) => {
      file.filePath  = this.getFilePath(file);
      file.iconClass = `fa-${file.blob_icon}`;
      file.blobPath  = file.blob_path;
      file.parallelLines = [];
      const linesObj = { left: [], right: [] };

      file.sections.forEach( (section) => {
        const { conflict, lines, id } = section;

        if (conflict) {
          linesObj.left.push(this.getOriginHeaderLine(id));
          linesObj.right.push(this.getHeadHeaderLine(id));
        }

        lines.forEach( (line) => {
          const { type } = line;

          if (conflict) {
            if (type === 'old') {
              linesObj.left.push(this.getLineForParallelView(line, id, 'conflict'));
            }
            else if (type === 'new') {
              linesObj.right.push(this.getLineForParallelView(line, id, 'conflict', true));
            }
          }
          else {
            const lineType = type || 'context';

            linesObj.left.push (this.getLineForParallelView(line, id, lineType));
            linesObj.right.push(this.getLineForParallelView(line, id, lineType, true));
          }
        });

        this.checkLineLengths(linesObj);
      });

      for (let i = 0, len = linesObj.left.length; i < len; i++) {
        file.parallelLines.push([
          linesObj.right[i],
          linesObj.left[i]
        ]);
      }

    });
  }


  checkLineLengths(linesObj) {
    let { left, right } = linesObj;

    if (left.length !== right.length) {
      if (left.length > right.length) {
        const diff = left.length - right.length;
        for (let i = 0; i < diff; i++) {
          right.push({ lineType: 'emptyLine', richText: '' });
        }
      }
      else {
        const diff = right.length - left.length;
        for (let i = 0; i < diff; i++) {
          left.push({ lineType: 'emptyLine', richText: '' });
        }
      }
    }
  }


  setInlineLines(data) {
    data.files.forEach( (file) => {
      file.iconClass   = `fa-${file.blob_icon}`;
      file.blobPath    = file.blob_path;
      file.filePath    = this.getFilePath(file);
      file.inlineLines = []

      file.sections.forEach( (section) => {
        let currentLineType = 'new';
        const { conflict, lines, id } = section;

        if (conflict) {
          file.inlineLines.push(this.getHeadHeaderLine(id));
        }

        lines.forEach( (line) => {
          const { type } = line;

          if ((type === 'new' || type === 'old') && currentLineType !== type) {
            currentLineType = type;
            file.inlineLines.push({ lineType: 'emptyLine', richText: '' });
          }

          this.decorateLineForInlineView(line, id, conflict);
          file.inlineLines.push(line);
        })

        if (conflict) {
          file.inlineLines.push(this.getOriginHeaderLine(id));
        }
      });
    });
  }


  handleSelected(file, sectionId, selection) {
    const vi = this.vueInstance;
    let files = vi.conflictsData.files;

    vi.$set(`conflictsData.files[${files.indexOf(file)}].resolutionData['${sectionId}']`, selection);


    files.forEach( (file) => {
      file.inlineLines.forEach( (line) => {
        if (line.id === sectionId && (line.hasConflict || line.isHeader)) {
          this.markLine(line, selection);
        }
      });

      file.parallelLines.forEach( (lines) => {
        const left         = lines[0];
        const right        = lines[1];
        const hasSameId    = right.id === sectionId || left.id === sectionId;
        const isLeftMatch  = left.hasConflict || left.isHeader;
        const isRightMatch = right.hasConflict || right.isHeader;

        if (hasSameId && (isLeftMatch || isRightMatch)) {
          this.markLine(left, selection);
          this.markLine(right, selection);
        }
      })
    });
  }


  updateViewType(newType) {
    const vi = this.vueInstance;

    if (newType === vi.diffViewType || !(newType === 'parallel' || newType === 'inline')) {
      return;
    }

    vi.diffViewType = newType;
    vi.isParallel   = newType === 'parallel';
    $.cookie('diff_view', newType, {
      path: (gon && gon.relative_url_root) || '/'
    });
    $('.content-wrapper .container-fluid')
      .toggleClass('container-limited', !vi.isParallel && vi.fixedLayout);
  }

  setFileResolveMode(file, mode) {
    const vi = this.vueInstance;

    // Restore Interactive mode when switching to Edit mode
    if (mode === EDIT_RESOLVE_MODE) {
      file.resolutionData = {};

      this.restoreFileLinesState(file);
    }

    file.resolveMode = mode;
  }


  restoreFileLinesState(file) {
    file.inlineLines.forEach((line) => {
      if (line.hasConflict || line.isHeader) {
        line.isSelected = false;
        line.isUnselected = false;
      }
    });

    file.parallelLines.forEach((lines) => {
      const left         = lines[0];
      const right        = lines[1];
      const isLeftMatch  = left.hasConflict || left.isHeader;
      const isRightMatch = right.hasConflict || right.isHeader;

      if (isLeftMatch || isRightMatch) {
        left.isSelected = false;
        left.isUnselected = false;
        right.isSelected = false;
        right.isUnselected = false;
      }
    });
  }


  setPromptConfirmationState(file, state) {
    file.promptDiscardConfirmation = state;
  }


  markLine(line, selection) {
    if (selection === 'head' && line.isHead) {
      line.isSelected   = true;
      line.isUnselected = false;
    }
    else if (selection === 'origin' && line.isOrigin) {
      line.isSelected   = true;
      line.isUnselected = false;
    }
    else {
      line.isSelected   = false;
      line.isUnselected = true;
    }
  }


  getConflictsCount() {
    const files = this.vueInstance.conflictsData.files;
    let count = 0;

    files.forEach((file) => {
      file.sections.forEach((section) => {
        if (section.conflict) {
          count++;
        }
      });
    });

    return count;
  }


  isReadyToCommit() {
    const vi = this.vueInstance;
    const files = this.vueInstance.conflictsData.files;
    const hasCommitMessage = $.trim(this.vueInstance.conflictsData.commitMessage).length;
    let unresolved = 0;

    for (let i = 0, l = files.length; i < l; i++) {
      let file = files[i];

      if (file.resolveMode === INTERACTIVE_RESOLVE_MODE) {
        let numberConflicts = 0;
        let resolvedConflicts = Object.keys(file.resolutionData).length

        for (let j = 0, k = file.sections.length; j < k; j++) {
          if (file.sections[j].conflict) {
            numberConflicts++;
          }
        }

        if (resolvedConflicts !== numberConflicts) {
          unresolved++;
        }
      } else if (file.resolveMode === EDIT_RESOLVE_MODE) {
        // Unlikely to happen since switching to Edit mode saves content automatically.
        // Checking anyway in case the save strategy changes in the future
        if (!file.content) {
          unresolved++;
          continue;
        }
      }
    }

    return !vi.isSubmitting && hasCommitMessage && !unresolved;
  }


  getCommitButtonText() {
    const initial = 'Commit conflict resolution';
    const inProgress = 'Committing...';
    const vue = this.vueInstance;

    return vue ? vue.isSubmitting ? inProgress : initial : initial;
  }


  decorateLineForInlineView(line, id, conflict) {
    const { type }    = line;
    line.id           = id;
    line.hasConflict  = conflict;
    line.isHead       = type === 'new';
    line.isOrigin     = type === 'old';
    line.hasMatch     = type === 'match';
    line.richText     = line.rich_text;
    line.isSelected   = false;
    line.isUnselected = false;
  }

  getLineForParallelView(line, id, lineType, isHead) {
    const { old_line, new_line, rich_text } = line;
    const hasConflict = lineType === 'conflict';

    return {
      id,
      lineType,
      hasConflict,
      isHead       : hasConflict && isHead,
      isOrigin     : hasConflict && !isHead,
      hasMatch     : lineType === 'match',
      lineNumber   : isHead ? new_line : old_line,
      section      : isHead ? 'head' : 'origin',
      richText     : rich_text,
      isSelected   : false,
      isUnselected : false
    }
  }


  getHeadHeaderLine(id) {
    return {
      id          : id,
      richText    : HEAD_HEADER_TEXT,
      buttonTitle : HEAD_BUTTON_TITLE,
      type        : 'new',
      section     : 'head',
      isHeader    : true,
      isHead      : true,
      isSelected  : false,
      isUnselected: false
    }
  }


  getOriginHeaderLine(id) {
    return {
      id          : id,
      richText    : ORIGIN_HEADER_TEXT,
      buttonTitle : ORIGIN_BUTTON_TITLE,
      type        : 'old',
      section     : 'origin',
      isHeader    : true,
      isOrigin    : true,
      isSelected  : false,
      isUnselected: false
    }
  }


  handleFailedRequest(vueInstance, data) {
    vueInstance.hasError = true;
    vueInstance.conflictsData.errorMessage = 'Something went wrong!';
  }


  getCommitData() {
    let conflictsData = this.vueInstance.conflictsData;
    let commitData = {};

    commitData = {
      commitMessage: conflictsData.commitMessage,
      files: []
    };

    conflictsData.files.forEach((file) => {
      let addFile;

      addFile = {
        old_path: file.old_path,
        new_path: file.new_path
      };

      // Submit only one data for type of editing
      if (file.resolveMode === INTERACTIVE_RESOLVE_MODE) {
        addFile.sections = file.resolutionData;
      } else if (file.resolveMode === EDIT_RESOLVE_MODE) {
        addFile.content = file.content;
      }

      commitData.files.push(addFile);
    });

    return commitData;
  }


  getFilePath(file) {
    const { old_path, new_path } = file;
    return old_path === new_path ? new_path : `${old_path} → ${new_path}`;
  }
}
