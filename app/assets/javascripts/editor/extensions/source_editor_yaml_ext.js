/**
 * A Yaml Editor Extension options for Source Editor
 * @typedef {Object} YamlEditorExtensionOptions
 * @property { boolean } enableComments Convert model nodes with the comment
 * pattern to comments?
 * @property { string } highlightPath Add a line highlight to the
 * node specified by this e.g. `"foo.bar[0]"`
 * @property { * } model Any JS Object that will be stringified and used as the
 * editor's value. Equivalent to using `setDataModel()`
 * @property options SourceEditorExtension Options
 */

import { toPath } from 'lodash';
import { parseDocument, Document, visit, isScalar, isCollection, isMap } from 'yaml';
import { findPair } from 'yaml/util';

export class YamlEditorExtension {
  static get extensionName() {
    return 'YamlEditor';
  }

  /**
   * @private
   * This wraps long comments to a maximum line length of 80 chars.
   *
   * The `yaml` package does not currently wrap comments. This function
   * is a local workaround and should be deprecated if
   * https://github.com/eemeli/yaml/issues/322
   * is resolved.
   */
  static wrapCommentString(string, level = 0) {
    if (!string) {
      return null;
    }
    if (level < 0 || Number.isNaN(parseInt(level, 10))) {
      throw Error(`Invalid value "${level}" for variable \`level\``);
    }
    const maxLineWidth = 80;
    const indentWidth = 2;
    const commentMarkerWidth = '# '.length;
    const maxLength = maxLineWidth - commentMarkerWidth - level * indentWidth;
    const lines = [[]];
    string.split(' ').forEach((word) => {
      const currentLine = lines.length - 1;
      if ([...lines[currentLine], word].join(' ').length <= maxLength) {
        lines[currentLine].push(word);
      } else {
        lines.push([word]);
      }
    });
    return lines.map((line) => ` ${line.join(' ')}`).join('\n');
  }

  /**
   * @private
   *
   * This utilizes `yaml`'s `visit` function to transform nodes with a
   * comment key pattern to actual comments.
   *
   * In Objects, a key of '#' will be converted to a comment at the top of a
   * property. Any key following the pattern `#|<some key>` will be placed
   * right before `<some key>`.
   *
   * In Arrays, any string that starts with #  (including the space), will
   * be converted to a comment at the position it was in.
   *
   * @param { Document } doc
   * @returns { Document }
   */
  static transformComments(doc) {
    const getLevel = (path) => {
      const { length } = path.filter((x) => isCollection(x));
      return length ? length - 1 : 0;
    };

    visit(doc, {
      Pair(_, pair, path) {
        const key = pair.key.value;
        // If the key is = '#', we add the value as a comment to the parent
        // We can then remove the node.
        if (key === '#') {
          Object.assign(path[path.length - 1], {
            commentBefore: YamlEditorExtension.wrapCommentString(pair.value.value, getLevel(path)),
          });
          return visit.REMOVE;
        }
        // If the key starts with `#|`, we want to add a comment to the
        // corresponding property. We can then remove the node.
        if (key.startsWith('#|')) {
          const targetProperty = key.split('|')[1];
          const target = findPair(path[path.length - 1].items, targetProperty);
          if (target) {
            target.key.commentBefore = YamlEditorExtension.wrapCommentString(
              pair.value.value,
              getLevel(path),
            );
          }
          return visit.REMOVE;
        }
        return undefined; // If the node is not a comment, do nothing with it
      },
      // Sequence is basically an array
      Seq(_, node, path) {
        let comment = null;
        const items = node.items.flatMap((child) => {
          if (comment) {
            Object.assign(child, { commentBefore: comment });
            comment = null;
          }
          if (
            isScalar(child) &&
            child.value &&
            child.value.startsWith &&
            child.value.startsWith('#')
          ) {
            const commentValue = child.value.replace(/^#\s?/, '');
            comment = YamlEditorExtension.wrapCommentString(commentValue, getLevel(path));
            return [];
          }
          return child;
        });
        Object.assign(node, { items });
        // Adding a comment in case the last one is a comment
        if (comment) {
          Object.assign(node, { comment });
        }
      },
    });
    return doc;
  }

  static getDoc(instance) {
    return parseDocument(instance.getValue());
  }

  static locate(instance, path) {
    if (!path) throw Error(`No path provided.`);
    const blob = instance.getValue();
    const doc = parseDocument(blob);
    const pathArray = Array.isArray(path) ? path : toPath(path);

    if (!doc.getIn(pathArray)) {
      return [null, null];
    }

    const parentNode = doc.getIn(pathArray.slice(0, pathArray.length - 1));
    let startChar;
    let endChar;
    if (isMap(parentNode)) {
      const node = parentNode.items.find(
        (item) => item.key.value === pathArray[pathArray.length - 1],
      );
      [startChar] = node.key.range;
      [, , endChar] = node.value.range;
    } else {
      const node = doc.getIn(pathArray);
      [startChar, , endChar] = node.range;
    }
    const startSlice = blob.slice(0, startChar);
    const endSlice = blob.slice(0, endChar);
    const startLine = (startSlice.match(/\n/g) || []).length + 1;
    const endLine = (endSlice.match(/\n/g) || []).length;
    return [startLine, endLine];
  }

  /**
   * Extends the source editor with capabilities for yaml files.
   *
   * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
   * @param {YamlEditorExtensionOptions} setupOptions
   */
  onSetup(instance, setupOptions = {}) {
    const { enableComments = false, highlightPath = null, model = null } = setupOptions;
    this.enableComments = enableComments;
    this.highlightPath = highlightPath;
    this.model = model;

    if (model) {
      this.initFromModel(instance, model);
    }

    instance.onDidChangeModelContent(() => instance.onUpdate());
  }

  initFromModel(instance, model) {
    const doc = new Document(model);
    if (this.enableComments) {
      YamlEditorExtension.transformComments(doc);
    }
    instance.setValue(doc.toString());
  }

  setDoc(instance, doc) {
    if (this.enableComments) {
      YamlEditorExtension.transformComments(doc);
    }

    if (!instance.getValue()) {
      instance.setValue(doc.toString());
    } else {
      instance.updateValue(doc.toString());
    }
  }

  highlight(instance, path, keepOnNotFound = false) {
    // IMPORTANT
    // removeHighlight and highlightLines both come from
    // SourceEditorExtension. So it has to be installed prior to this extension
    if (this.highlightPath === path) return;

    if (!path || !path.length) {
      instance.removeHighlights();
      this.highlightPath = null;
      return;
    }

    const [startLine, endLine] = YamlEditorExtension.locate(instance, path);

    if (startLine === null) {
      // Path could not be found.
      if (!keepOnNotFound) {
        instance.removeHighlights();
        this.highlightPath = null;
      }
      return;
    }

    instance.highlightLines([startLine, endLine]);
    this.highlightPath = path;
  }

  provides() {
    return {
      /**
       * Get the editor's value parsed as a `Document` as defined by the `yaml`
       * package
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
       * @returns {Document}
       */
      getDoc: (instance) => YamlEditorExtension.getDoc(instance),

      /**
       * Accepts a `Document` as defined by the `yaml` package and
       * sets the Editor's value to a stringified version of it.
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
       * @param { Document } doc
       */
      setDoc: (instance, doc) => this.setDoc(instance, doc),

      /**
       * Returns the parsed value of the Editor's content as JS.
       * @returns {*}
       */
      getDataModel: (instance) => YamlEditorExtension.getDoc(instance).toJS(),

      /**
       * Accepts any JS Object and sets the Editor's value to a stringified version
       * of that value.
       *
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
       * @param value
       */
      setDataModel: (instance, value) => this.setDoc(instance, new Document(value)),

      /**
       * Method to be executed when the Editor's <TextModel> was updated
       */
      onUpdate: (instance) => {
        if (this.highlightPath) {
          this.highlight(instance, this.highlightPath);
        }
      },

      /**
       * Set the editors content to the input without recreating the content model.
       *
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
       * @param blob
       */
      updateValue: (instance, blob) => {
        // Using applyEdits() instead of setValue() ensures that tokens such as
        // highlighted lines aren't deleted/recreated which causes a flicker.
        const model = instance.getModel();
        model.applyEdits([
          {
            // A nice improvement would be to replace getFullModelRange() with
            // a range of the actual diff, avoiding re-formatting the document,
            // but that's something for a later iteration.
            range: model.getFullModelRange(),
            text: blob,
          },
        ]);
      },

      /**
       * Add a line highlight style to the node specified by the path.
       *
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
       * @param {string|(string|number)[]|null|false} path A path to a node
       * of the Editor's
       * value,
       * e.g. `"foo.bar[0]"`. If the value is falsy, this will remove all
       * highlights.
       * @param {boolean} [keepOnNotFound=false] If the passed path cannot
       * be located, keep the previous highlight state
       */
      highlight: (instance, path, keepOnNotFound) => this.highlight(instance, path, keepOnNotFound),

      /**
       * Return the line numbers of a certain node identified by `path` within
       * the yaml.
       *
       * @param {module:source_editor_instance~EditorInstance} instance - The Source Editor instance
       * @param {string|(string|number)[]} path A path to a node, eg.
       * `foo.bar[0]`
       * @returns {number[]} Array following the schema `[firstLine, lastLine]`
       * (both inclusive)
       *
       * @throws {Error} Will throw if the path is not found inside the document
       */
      locate: (instance, path) => YamlEditorExtension.locate(instance, path),

      initFromModel: (instance, model) => this.initFromModel(instance, model),
    };
  }
}
