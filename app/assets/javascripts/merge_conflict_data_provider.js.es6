const HEAD_HEADER_TEXT   = 'HEAD//our changes';
const ORIGIN_HEADER_TEXT = 'origin//their changes';

window.MergeConflictDataProvider = class MergeConflictDataProvider {

  getInitialData() {
    const diffViewType = $.cookie('diff_view');

    return {
      isLoading      : true,
      hasError       : false,
      isParallel     : diffViewType === 'parallel',
      diffViewType   : diffViewType,
      conflictsData  : {},
      resolutionData : {}
    }
  }


  decorateData(vueInstance, data) {
    this.vueInstance    = vueInstance;

    if (data.type === 'error') {
      vueInstance.hasError = true;
      data.errorMessage = data.message;
    }
    else {
      data.shortCommitSha = data.commit_sha.slice(0, 7);
      data.commitMessage  = data.commit_message;

      this.setParallelLines(data);
      this.setInlineLines(data);
      this.updateResolutionsData(data);
    }

    vueInstance.conflictsData = data;
  }


  updateResolutionsData(data) {
    const vi = this.vueInstance;

    data.files.forEach( (file) => {
      file.sections.forEach( (section) => {
        if (section.conflict) {
          vi.$set(`resolutionData['${section.id}']`, false);
        }
      });
    });
  }


  setParallelLines(data) {
    data.files.forEach( (file) => {
      file.filePath = this.getFilePath(file);
      file.parallelLines = { left: [], right: [] };

      file.sections.forEach( (section) => {
        const { conflict, lines, id } = section;

        if (conflict) {
          file.parallelLines.left.push(this.getOriginHeaderLine(id));
          file.parallelLines.right.push(this.getHeadHeaderLine(id));
        }

        lines.forEach( (line) => {
          const { type } = line;

          if (conflict) {
            if (type === 'old') {
              file.parallelLines.left.push(this.getLineForParallelView(line, id, 'conflict'));
            }
            else if (type === 'new') {
              file.parallelLines.right.push(this.getLineForParallelView(line, id, 'conflict', true));
            }
          }
          else {
            const lineType = type || 'context';

            file.parallelLines.left.push (this.getLineForParallelView(line, id, lineType));
            file.parallelLines.right.push(this.getLineForParallelView(line, id, lineType, true));
          }
        });

        this.checkLineLengths(file);
      });
    });
  }


  checkLineLengths(file) {
    let { left, right } = file.parallelLines;

    if (left.length !== right.length) {
      if (left.length > right.length) {
        const diff = left.length - right.length;
        for (let i = 0; i < diff; i++) {
          file.parallelLines.right.push({ lineType: 'emptyLine', richText: '' });
        }
      }
      else {
        const diff = right.length - left.length;
        for (let i = 0; i < diff; i++) {
          file.parallelLines.left.push({ lineType: 'emptyLine', richText: '' });
        }
      }
    }
  }


  setInlineLines(data) {
    data.files.forEach( (file) => {
      file.inlineLines = []
      file.filePath = this.getFilePath(file);

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


  handleSelected(sectionId, selection) {
    const vi = this.vueInstance;

    vi.resolutionData[sectionId] = selection;
    vi.conflictsData.files.forEach( (file) => {
      file.inlineLines.forEach( (line) => {
        if (line.id === sectionId && (line.hasConflict || line.isHeader)) {
          this.markLine(line, selection);
        }
      });


      for (section in file.parallelLines) {
        const lines = file.parallelLines[section];

        lines.forEach( (line) => {
          if (line.id === sectionId && (line.hasConflict || line.isHeader )) {
            this.markLine(line, selection);
          }
        })
      }
    });
  }


  updateViewType(newType) {
    const vi = this.vueInstance;

    if (newType === vi.diffView || !(newType === 'parallel' || newType === 'inline')) {
      return;
    }

    vi.diffView   = newType;
    vi.isParallel = newType === 'parallel';
    $.cookie('diff_view', newType); // TODO: Make sure that cookie path added.
    $('.content-wrapper .container-fluid').toggleClass('container-limited');
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
    return Object.keys(this.vueInstance.resolutionData).length;
  }


  getResolvedCount() {
    let  count = 0;
    const data = this.vueInstance.resolutionData;

    for (const id in data) {
      const resolution = data[id];
      if (resolution) {
        count++;
      }
    }

    return count;
  }


  isAllResolved() {
    return this.getConflictsCount() === this.getResolvedCount();
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
    return {
      commit_message: this.vueInstance.conflictsData.commitMessage,
      sections: this.vueInstance.resolutionData
    }
  }


  getFilePath(file) {
    const { old_path, new_path } = file;
    return old_path === new_path ? new_path : `${old_path} &rarr; ${new_path}`;
  }

}
