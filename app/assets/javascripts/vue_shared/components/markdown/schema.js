import { Node } from 'tiptap'
import { setBlockType } from 'tiptap-commands'
import { Schema } from 'prosemirror-model'
import editorExtensions from './editor_extensions';

class DocNode extends Node {
  get name() {
    return 'doc'
  }

  get schema() {
    return {
      content: 'block+',
    }
  }
}

class ParagraphNode extends Node {
  get name() {
    return 'paragraph'
  }

  get schema() {
    return {
      content: 'inline*',
      group: 'block',
      draggable: false,
      parseDOM: [{
        tag: 'p',
      }],
      toDOM: () => ['p', 0],
    }
  }

  command({ type }) {
    return setBlockType(type)
  }
}

class TextNode extends Node {
  get name() {
    return 'text'
  }

  get schema() {
    return {
      group: 'inline',
    }
  }
}

const builtInNodes = [
  new DocNode(),
  new ParagraphNode(),
  new TextNode(),
];

const allExtensions = [
  ...builtInNodes,
  ...editorExtensions,
];

const nodes = allExtensions
  .filter(extension => extension.type === 'node')
  .reduce((nodes, { name, schema }) => ({
    ...nodes,
    [name]: schema,
  }), {})

const marks = allExtensions
  .filter(extension => extension.type === 'mark')
  .reduce((marks, { name, schema }) => ({
    ...marks,
    [name]: schema,
  }), {});

export default new Schema({
  nodes: nodes,
  marks: marks,
});
