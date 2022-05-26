/**
 * This module implements a function that converts a Hast Abstract
 * Syntax Tree (AST) to a ProseMirror document.
 *
 * It is based on the prosemirror-markdown’s from_markdown module
 * https://github.com/ProseMirror/prosemirror-markdown/blob/master/src/from_markdown.js.
 *
 * It deviates significantly from the original because
 * prosemirror-markdown supports converting an markdown-it AST instead of a
 * HAST one. It also adds sourcemap attributes automatically to every
 * ProseMirror node and mark created during the conversion process.
 *
 * We recommend becoming familiar with HAST and ProseMirror documents to
 * facilitate the understanding of the behavior implemented in this module.
 *
 * Unist syntax tree documentation: https://github.com/syntax-tree/unist
 * Hast tree documentation: https://github.com/syntax-tree/hast
 * ProseMirror document documentation: https://prosemirror.net/docs/ref/#model.Document_Structure
 * visit-parents documentation: https://github.com/syntax-tree/unist-util-visit-parents
 */

import { Mark } from 'prosemirror-model';
import { visitParents } from 'unist-util-visit-parents';
import { toString } from 'hast-util-to-string';
import { isFunction } from 'lodash';

/**
 * Merges two ProseMirror text nodes if both text nodes
 * have the same set of marks.
 *
 * @param {ProseMirror.Node} a first ProseMirror node
 * @param {ProseMirror.Node} b second ProseMirror node
 * @returns {model.Node} A new text node that results from combining
 * the text of the two text node parameters or null.
 */
function maybeMerge(a, b) {
  if (a && a.isText && b && b.isText && Mark.sameSet(a.marks, b.marks)) {
    return a.withText(a.text + b.text);
  }

  return null;
}

/**
 * Creates an object that contains sourcemap position information
 * included in a Hast Abstract Syntax Tree. The Content
 * Editor uses the sourcemap information to restore the
 * original source of a node when the user doesn’t change it.
 *
 * Unist syntax tree documentation: https://github.com/syntax-tree/unist
 * Hast node documentation: https://github.com/syntax-tree/hast
 *
 * @param {HastNode} hastNode A Hast node
 * @param {String} source Markdown source file
 *
 * @returns It returns an object with the following attributes:
 *
 * - sourceMapKey: A string that uniquely identifies what is
 * the position of the hast node in the Markdown source file.
 * - sourceMarkdown: A node’s original Markdown source extrated
 * from the Markdown source file.
 */
function createSourceMapAttributes(hastNode, source) {
  const { position } = hastNode;

  return position.end
    ? {
        sourceMapKey: `${position.start.offset}:${position.end.offset}`,
        sourceMarkdown: source.substring(position.start.offset, position.end.offset),
      }
    : {};
}

/**
 * Compute ProseMirror node’s attributes from a Hast node.
 * By default, this function includes sourcemap position
 * information in the object returned.
 *
 * Other attributes are retrieved by invoking a getAttrs
 * function provided by the ProseMirror node factory spec.
 *
 * @param {*} proseMirrorNodeSpec ProseMirror node spec object
 * @param {HastNode} hastNode A hast node
 * @param {Array<HastNode>} hastParents All the ancestors of the hastNode
 * @param {String} source Markdown source file’s content
 *
 * @returns An object that contains a ProseMirror node’s attributes
 */
function getAttrs(proseMirrorNodeSpec, hastNode, hastParents, source) {
  const { getAttrs: specGetAttrs } = proseMirrorNodeSpec;

  return {
    ...createSourceMapAttributes(hastNode, source),
    ...(isFunction(specGetAttrs) ? specGetAttrs(hastNode, hastParents, source) : {}),
  };
}

/**
 * Keeps track of the Hast -> ProseMirror conversion process.
 *
 * When the `openNode` method is invoked, it adds the node to a stack
 * data structure. When the `closeNode` method is invoked, it removes the
 * last element from the Stack, creates a ProseMirror node, and adds that
 * ProseMirror node to the previous node in the Stack.
 *
 * For example, given a Hast tree with three levels of nodes:
 *
 * - blockquote
 *   - paragraph
 *     - text
 *
 * 3. text
 * 2. paragraph
 * 1. blockquote
 *
 * Calling `closeNode` will fold the text node into paragraph. A 2nd
 * call to this method will fold "paragraph" into "blockquote".
 *
 * Mark state
 *
 * When the `openMark` method is invoked, this class adds the Mark to a `MarkSet`
 * object. When a text node is added, it assigns all the opened marks to that text
 * node and cleans the marks. It takes care of merging text nodes with the same
 * set of marks as well.
 */
class HastToProseMirrorConverterState {
  constructor() {
    this.stack = [];
    this.marks = Mark.none;
  }

  /**
   * Gets the first element of the node stack
   */
  get top() {
    return this.stack[this.stack.length - 1];
  }

  /**
   * Detects if the node stack is empty
   */
  get empty() {
    return this.stack.length === 0;
  }

  /**
   * Creates a text node and adds it to
   * the top node in the stack.
   *
   * It applies the marks stored temporarily
   * by calling the `addMark` method. After
   * the text node is added, it clears the mark
   * set afterward.
   *
   * If the top block node has a text
   * node with the same set of marks as the
   * text node created, this method merges
   * both text nodes
   *
   * @param {ProseMirror.Schema} schema ProseMirror schema
   * @param {String} text Text
   * @returns
   */
  addText(schema, text) {
    if (!text) return;
    const nodes = this.top.content;
    const last = nodes[nodes.length - 1];
    const node = schema.text(text, this.marks);
    const merged = maybeMerge(last, node);

    if (last && merged) {
      nodes[nodes.length - 1] = merged;
    } else {
      nodes.push(node);
    }

    this.closeMarks();
  }

  /**
   * Adds a mark to the set of marks stored temporarily
   * until addText is called.
   * @param {*} markType
   * @param {*} attrs
   */
  openMark(markType, attrs) {
    this.marks = markType.create(attrs).addToSet(this.marks);
  }

  /**
   * Empties the temporary Mark set.
   */
  closeMarks() {
    this.marks = Mark.none;
  }

  /**
   * Adds a node to the stack data structure.
   *
   * @param {Schema.NodeType} type ProseMirror Schema for the node
   * @param {HastNode} hastNode Hast node from which the ProseMirror node will be created
   * @param {*} attrs Node’s attributes
   * @param {*} factorySpec The factory spec used to create the node factory
   */
  openNode(type, hastNode, attrs, factorySpec) {
    this.stack.push({ type, attrs, content: [], hastNode, factorySpec });
  }

  /**
   * Removes the top ProseMirror node from the
   * conversion stack and adds the node to the
   * previous element.
   * @returns
   */
  closeNode() {
    const { type, attrs, content } = this.stack.pop();
    const node = type.createAndFill(attrs, content);

    if (!node) return null;

    if (this.marks.length) {
      this.marks = Mark.none;
    }

    if (!this.empty) {
      this.top.content.push(node);
    }

    return node;
  }

  closeUntil(hastNode) {
    while (hastNode !== this.top?.hastNode) {
      this.closeNode();
    }
  }
}

/**
 * Create ProseMirror node/mark factories based on one or more
 * factory specifications.
 *
 * Note: Read `createProseMirrorDocFromMdastTree` documentation
 * for instructions about how to define these specifications.
 *
 * @param {model.ProseMirrorSchema} schema A ProseMirror schema used to create the
 * ProseMirror nodes and marks.
 * @param {Object} proseMirrorFactorySpecs ProseMirror nodes factory specifications.
 * @param {String} source Markdown source file’s content
 *
 * @returns An object that contains ProseMirror node factories
 */
const createProseMirrorNodeFactories = (schema, proseMirrorFactorySpecs, source) => {
  const factories = {
    root: {
      selector: 'root',
      handle: (state, hastNode) =>
        state.openNode(
          schema.topNodeType,
          hastNode,
          {},
          {
            wrapTextInParagraph: true,
          },
        ),
    },
    text: {
      selector: 'text',
      handle: (state, hastNode, parent) => {
        const { factorySpec } = state.top;

        if (/^\s+$/.test(hastNode.value)) {
          return;
        }

        if (factorySpec.wrapTextInParagraph === true) {
          state.openNode(schema.nodeType('paragraph'), hastNode, getAttrs({}, parent, [], source));
          state.addText(schema, hastNode.value);
          state.closeNode();
        } else {
          state.addText(schema, hastNode.value);
        }
      },
    },
  };
  for (const [proseMirrorName, factorySpec] of Object.entries(proseMirrorFactorySpecs)) {
    const factory = {
      selector: factorySpec.selector,
      skipChildren: factorySpec.skipChildren,
    };

    if (factorySpec.type === 'block') {
      factory.handle = (state, hastNode, parent) => {
        const nodeType = schema.nodeType(proseMirrorName);

        state.closeUntil(parent);
        state.openNode(
          nodeType,
          hastNode,
          getAttrs(factorySpec, hastNode, parent, source),
          factorySpec,
        );

        /**
         * If a getContent function is provided, we immediately close
         * the node to delegate content processing to this function.
         * */
        if (isFunction(factorySpec.getContent)) {
          state.addText(
            schema,
            factorySpec.getContent({ hastNode, hastNodeText: toString(hastNode) }),
          );
          state.closeNode();
        }
      };
    } else if (factorySpec.type === 'inline') {
      const nodeType = schema.nodeType(proseMirrorName);
      factory.handle = (state, hastNode, parent) => {
        state.closeUntil(parent);
        state.openNode(
          nodeType,
          hastNode,
          getAttrs(factorySpec, hastNode, parent, source),
          factorySpec,
        );
        // Inline nodes do not have children therefore they are immediately closed
        state.closeNode();
      };
    } else if (factorySpec.type === 'mark') {
      const markType = schema.marks[proseMirrorName];
      factory.handle = (state, hastNode, parent) => {
        state.openMark(markType, getAttrs(factorySpec, hastNode, parent, source));

        if (factorySpec.inlineContent) {
          state.addText(schema, hastNode.value);
        }
      };
    } else {
      throw new RangeError(
        `Unrecognized ProseMirror object type ${JSON.stringify(factorySpec.type)}`,
      );
    }

    factories[proseMirrorName] = factory;
  }

  return factories;
};

const findFactory = (hastNode, factories) =>
  Object.entries(factories).find(([, factorySpec]) => {
    const { selector } = factorySpec;

    return isFunction(selector)
      ? selector(hastNode)
      : [hastNode.tagName, hastNode.type].includes(selector);
  })?.[1];

/**
 * Converts a Hast AST to a ProseMirror document based on a series
 * of specifications that describe how to map all the nodes of the former
 * to ProseMirror nodes or marks.
 *
 * The specification object describes how to map a Hast node to a ProseMirror node or mark.
 * The converter will trigger an error if it doesn’t find a specification
 * for a Hast node while traversing the AST.
 *
 * The object should have the following shape:
 *
 * {
 *   [ProseMirrorNodeOrMarkName]: {
 *     type: 'block' | 'inline' | 'mark',
 *     selector: String | hastNode -> Boolean,
 *     ...configurationOptions
 *   }
 * }
 *
 * Where each property in the object represents a HAST node with a given tag name, for example:
 *
 *  {
 *    horizontalRule: {
 *      type: 'block',
 *      selector: 'hr',
 *    },
 *    heading: {
 *      type: 'block',
 *      selector: (hastNode) => ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].includes(hastNode),
 *    },
 *    bold: {
 *      type: 'mark'
 *      selector: (hastNode) => ['b', 'strong'].includes(hastNode),
 *    },
 *    // etc
 *  }
 *
 *
 * Configuration options
 * ----------------------
 *
 * You can customize the conversion process for every node or mark
 * setting the following properties in the specification object:
 *
 * **type**
 *
 * The `type` property should have one of following three values:
 *
 * 1. "block": A ProseMirror node that contains one or more children.
 * 2. "inline": A ProseMirror node that doesn’t contain any children although
 *    it can have inline content like an image or a mention object.
 * 3. "mark": A ProseMirror mark.
 *
 * **selector**
 *
 * The `selector` property matches a HastNode to a ProseMirror node or
 * Mark. If you assign a string value to this property, the converter
 * will match the first hast node with a `tagName` or `type` property
 * that equals the string value.
 *
 * If you assign a function, the converter will invoke the function with
 * the hast node. The function should return `true` if the hastNode matches
 * the custom criteria implemented in the function
 *
 * **getAttrs**
 *
 * Computes a ProseMirror node or mark attributes. The converter will invoke
 * `getAttrs` with the following parameters:
 *
 * 1. hastNode: The hast node
 * 2. hasParents: All the hast node’s ancestors up to the root node
 * 3. source: Markdown source file’s content
 *
 * **wrapTextInParagraph**
 *
 * This property only applies to block nodes. If a block node contains text,
 * it will wrap that text in a paragraph. This is useful for ProseMirror block
 * nodes that don’t allow text directly such as list items and tables.
 *
 * **skipChildren**
 *
 * Skips a hast node’s children while traversing the tree.
 *
 * **getContent**
 *
 * Allows to pass a custom function that returns the content of a block node. The
 * Content is limited to a single text node therefore the function should return
 * a String value.
 *
 * Use this property along skipChildren to provide custom processing of child nodes
 * for a block node.
 *
 * @param {model.Document_Schema} params.schema A ProseMirror schema that specifies the shape
 * of the ProseMirror document.
 * @param {Object} params.factorySpec A factory specification as described above
 * @param {Hast} params.tree https://github.com/syntax-tree/hast
 * @param {String} params.source Markdown source from which the MDast tree was generated
 *
 * @returns A ProseMirror document
 */
export const createProseMirrorDocFromMdastTree = ({ schema, factorySpecs, tree, source }) => {
  const proseMirrorNodeFactories = createProseMirrorNodeFactories(schema, factorySpecs, source);
  const state = new HastToProseMirrorConverterState();

  visitParents(tree, (hastNode, ancestors) => {
    const factory = findFactory(hastNode, proseMirrorNodeFactories);

    if (!factory) {
      throw new Error(
        `Hast node of type "${
          hastNode.tagName || hastNode.type
        }" not supported by this converter. Please, provide an specification.`,
      );
    }

    const parent = ancestors[ancestors.length - 1];

    factory.handle(state, hastNode, parent);

    return factory.skipChildren === true ? 'skip' : true;
  });

  let doc;

  do {
    doc = state.closeNode();
  } while (!state.empty);

  return doc;
};
