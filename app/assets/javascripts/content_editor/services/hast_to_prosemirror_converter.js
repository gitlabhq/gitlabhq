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

import { Mark } from '@tiptap/pm/model';
import { visitParents, SKIP } from 'unist-util-visit-parents';
import { isFunction, isString, noop, mapValues } from 'lodash';

const NO_ATTRIBUTES = {};

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
 * @param {String} markdown Markdown source file
 *
 * @returns It returns an object with the following attributes:
 *
 * - sourceMapKey: A string that uniquely identifies what is
 * the position of the hast node in the Markdown source file.
 * - sourceMarkdown: A node’s original Markdown source extrated
 * from the Markdown source file.
 */
function createSourceMapAttributes(hastNode, markdown) {
  const { position } = hastNode;

  return position && position.end
    ? {
        sourceMapKey: `${position.start.offset}:${position.end.offset}`,
        sourceMarkdown: markdown.substring(position.start.offset, position.end.offset),
      }
    : {};
}

/**
 * Creates a function that resolves the attributes
 * of a ProseMirror node based on a hast node.
 *
 * @param {Object} params Parameters
 * @param {String} params.markdown Markdown source from which the AST was generated
 * @param {Object} params.attributeTransformer An object that allows applying a transformation
 * function to all the attributes listed in the attributes property.
 * @param {Array} params.attributeTransformer.attributes A list of attributes names
 * that the getAttrs function should apply the transformation
 * @param {Function} params.attributeTransformer.transform A function that applies
 * a transform operation on an attribute value.
 * @returns A `getAttrs` function
 */
const getAttrsFactory = ({ attributeTransformer, markdown }) =>
  /**
   * Compute ProseMirror node’s attributes from a Hast node.
   * By default, this function includes sourcemap position
   * information in the object returned.
   *
   * Other attributes are retrieved by invoking a getAttrs
   * function provided by the ProseMirror node factory spec.
   *
   * @param {Object} proseMirrorNodeSpec ProseMirror node spec object
   * @param {Object} hastNode A hast node
   * @param {Array} hastParents All the ancestors of the hastNode
   * @param {String} markdown Markdown source file’s content
   * @returns An object that contains a ProseMirror node’s attributes
   */
  function getAttrs(proseMirrorNodeSpec, hastNode, hastParents) {
    const { getAttrs: specGetAttrs } = proseMirrorNodeSpec;
    const attributes = {
      ...(isFunction(specGetAttrs) ? specGetAttrs(hastNode, hastParents, markdown) : {}),
    };
    const { transform } = attributeTransformer;

    return {
      ...createSourceMapAttributes(hastNode, markdown),
      ...mapValues(attributes, (attributeValue, attributeName) =>
        transform(attributeName, attributeValue, hastNode),
      ),
    };
  };

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

  get topNode() {
    return this.findInStack((item) => item.type === 'node');
  }

  /**
   * Detects if the node stack is empty
   */
  get empty() {
    return this.stack.length === 0;
  }

  findInStack(fn) {
    const last = this.stack.length - 1;

    for (let i = last; i >= 0; i -= 1) {
      const item = this.stack[i];

      if (fn(item) === true) {
        return item;
      }
    }

    return null;
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
    const nodes = this.topNode?.content;
    const last = nodes[nodes.length - 1];
    const node = schema.text(text, this.marks);
    const merged = maybeMerge(last, node);

    if (last && merged) {
      nodes[nodes.length - 1] = merged;
    } else {
      nodes.push(node);
    }
  }

  /**
   * Adds a mark to the set of marks stored temporarily
   * until an inline node is created.
   * @param {https://prosemirror.net/docs/ref/#model.MarkType} schemaType Mark schema type
   * @param {https://github.com/syntax-tree/hast#nodes} hastNode AST node that the mark is based on
   * @param {Object} attrs Mark attributes
   * @param {Object} factorySpec Specifications on how th mark should be created
   */
  // eslint-disable-next-line max-params
  openMark(schemaType, hastNode, attrs, factorySpec) {
    const mark = schemaType.create(attrs);
    this.stack.push({
      type: 'mark',
      mark,
      attrs,
      hastNode,
      factorySpec,
    });

    this.marks = mark.addToSet(this.marks);
  }

  /**
   * Removes a mark from the list of active marks that
   * are applied to inline nodes.
   */
  closeMark() {
    const { mark } = this.stack.pop();

    this.marks = mark.removeFromSet(this.marks);
  }

  /**
   * Adds a node to the stack data structure.
   *
   * @param {https://prosemirror.net/docs/ref/#model.NodeType} schemaType ProseMirror Schema for the node
   * @param {https://github.com/syntax-tree/hast#nodes} hastNode Hast node from which the ProseMirror node will be created
   * @param {*} attrs Node’s attributes
   * @param {*} factorySpec The factory spec used to create the node factory
   */
  // eslint-disable-next-line max-params
  openNode(schemaType, hastNode, attrs, factorySpec) {
    this.stack.push({
      type: 'node',
      schemaType,
      attrs,
      content: [],
      hastNode,
      factorySpec,
    });
  }

  /**
   * Removes the top ProseMirror node from the
   * conversion stack and adds the node to the
   * previous element.
   */
  closeNode() {
    const { schemaType, attrs, content, factorySpec } = this.stack.pop();
    const node =
      factorySpec.type === 'inline' && this.marks.length
        ? schemaType.createAndFill(attrs, content, this.marks)
        : schemaType.createAndFill(attrs, content);

    if (!node) {
      /*
      When the node returned by `createAndFill` is null is because the `content` passed as a parameter
      doesn’t conform with the document schema. We are handling the most likely scenario here that happens
      when a paragraph is inside another paragraph.

      This scenario happens when the converter encounters a mark wrapping one or more paragraphs.
      In this case, the converter will wrap the mark in a paragraph as well because ProseMirror does
      not allow marks wrapping block nodes or being direct children of certain nodes like the root nodes
      or list items.
      */
      if (
        schemaType.name === 'paragraph' &&
        content.some((child) => child.type.name === 'paragraph')
      ) {
        this.topNode.content.push(...content);
      }
      return null;
    }

    if (!this.empty) {
      this.topNode.content.push(node);
    }

    return node;
  }

  closeUntil(hastNode) {
    while (hastNode !== this.top?.hastNode) {
      if (this.top.type === 'node') {
        this.closeNode();
      } else {
        this.closeMark();
      }
    }
  }

  buildDoc() {
    let doc;

    do {
      if (this.top.type === 'node') {
        doc = this.closeNode();
      } else {
        this.closeMark();
      }
    } while (!this.empty);

    return doc;
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
 * @param {String} markdown Markdown source file’s content
 *
 * @returns An object that contains ProseMirror node factories
 */
const createProseMirrorNodeFactories = (
  schema,
  proseMirrorFactorySpecs,
  attributeTransformer,
  markdown,
  // eslint-disable-next-line max-params
) => {
  const getAttrs = getAttrsFactory({ attributeTransformer, markdown });
  const factories = {
    root: {
      selector: 'root',
      wrapInParagraph: true,
      handle: (state, hastNode) =>
        state.openNode(schema.topNodeType, hastNode, NO_ATTRIBUTES, factories.root),
    },
    text: {
      selector: 'text',
      handle: (state, hastNode, parent) => {
        const found = state.findInStack((node) => isFunction(node.factorySpec.processText));
        const { value: text } = hastNode;

        if (/^\s+$/.test(text)) {
          return;
        }

        state.closeUntil(parent);
        state.addText(schema, found ? found.factorySpec.processText(text) : text);
      },
    },
  };
  for (const [proseMirrorName, factorySpec] of Object.entries(proseMirrorFactorySpecs)) {
    const factory = {
      ...factorySpec,
    };

    if (factorySpec.type === 'block') {
      factory.handle = (state, hastNode, parent) => {
        const nodeType = schema.nodeType(proseMirrorName);

        state.closeUntil(parent);
        state.openNode(nodeType, hastNode, getAttrs(factory, hastNode, parent), factory);
      };
    } else if (factory.type === 'inline') {
      const nodeType = schema.nodeType(proseMirrorName);
      factory.handle = (state, hastNode, parent) => {
        state.closeUntil(parent);
        state.openNode(nodeType, hastNode, getAttrs(factory, hastNode, parent), factory);
        // Inline nodes do not have children therefore they are immediately closed
        state.closeNode();
      };
    } else if (factory.type === 'mark') {
      const markType = schema.marks[proseMirrorName];
      factory.handle = (state, hastNode, parent) => {
        state.openMark(markType, hastNode, getAttrs(factory, hastNode, parent), factory);
      };
    } else if (factory.type === 'ignore') {
      factory.handle = noop;
    } else {
      throw new RangeError(
        `Unrecognized ProseMirror object type ${JSON.stringify(factorySpec.type)}`,
      );
    }

    factories[proseMirrorName] = factory;
  }

  return factories;
};

const findFactory = (hastNode, ancestors, factories) =>
  Object.entries(factories).find(([, factorySpec]) => {
    const { selector } = factorySpec;

    return isFunction(selector)
      ? selector(hastNode, ancestors)
      : [hastNode.tagName, hastNode.type].includes(selector);
  })?.[1];

const findParent = (ancestors, parent) => {
  if (isString(parent)) {
    return ancestors.reverse().find((ancestor) => ancestor.tagName === parent);
  }

  return ancestors[ancestors.length - 1];
};

const resolveNodePosition = (textNode) => {
  const { position, value, type } = textNode;

  if (type !== 'text' || (!position.start && !position.end) || (position.start && position.end)) {
    return textNode.position;
  }

  const span = value.length - 1;

  if (position.start && !position.end) {
    const { start } = position;

    return {
      start,
      end: {
        row: start.row,
        column: start.column + span,
        offset: start.offset + span,
      },
    };
  }

  const { end } = position;

  return {
    start: {
      row: end.row,
      column: end.column - span,
      offset: end.offset - span,
    },
    end,
  };
};

const removeEmptyTextNodes = (nodes) =>
  nodes.filter(
    (node) => node.type !== 'text' || (node.type === 'text' && !/^\s+$/.test(node.value)),
  );

const wrapInlineElements = (nodes, wrappableTags) =>
  nodes.reduce((children, child) => {
    const previous = children[children.length - 1];

    if (
      child.type === 'comment' ||
      (child.type !== 'text' && !wrappableTags.includes(child.tagName))
    ) {
      return [...children, child];
    }

    const wrapperExists = previous?.properties?.wrapper;

    if (wrapperExists) {
      const wrapper = previous;

      wrapper.position.end = child.position.end;
      wrapper.children.push(child);

      return children;
    }

    const wrapper = {
      type: 'element',
      tagName: 'p',
      position: resolveNodePosition(child),
      children: [child],
      properties: { wrapper: true },
    };

    return [...children, wrapper];
  }, []);

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
 * 4. "ignore": A hast node that should be ignored and won’t be mapped to a
 *     ProseMirror node.
 *
 * **selector**
 *
 * The `selector` property matches a HastNode to a ProseMirror node or
 * Mark. If you assign a string value to this property, the converter
 * will match the first hast node with a `tagName` or `type` property
 * that equals the string value.
 *
 * If you assign a function, the converter will invoke the function with
 * the hast node and its ancestors. The function should return `true`
 * if the hastNode matches the custom criteria implemented in the function
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
 * **wrapInParagraph**
 *
 * This property only applies to block nodes. If a block node contains inline
 * elements like text, images, links, etc, the converter will wrap those inline
 * elements in a paragraph. This is useful for ProseMirror block
 * nodes that don’t allow text directly such as list items and tables.
 *
 * **processText**
 *
 * This property only applies to block nodes. If a block node contains text,
 * it allows applying a processing function to that text. This is useful when
 * you can transform the text node, i.e trim(), substring(), etc.
 *
 * **parent**
 *
 * Specifies what is the node’s parent. This is useful when the node’s parent is not
 * its direct ancestor in Abstract Syntax Tree. For example, imagine that you want
 * to make <tr> elements a direct children of tables and skip `<thead>` and `<tbody>`
 * altogether.
 *
 * @param {model.Document_Schema} params.schema A ProseMirror schema that specifies the shape
 * of the ProseMirror document.
 * @param {Object} params.factorySpec A factory specification as described above
 * @param {Hast} params.tree https://github.com/syntax-tree/hast
 * @param {String} params.source Markdown source from which the MDast tree was generated
 *
 * @returns A ProseMirror document
 */
export const createProseMirrorDocFromMdastTree = ({
  schema,
  factorySpecs,
  wrappableTags,
  tree,
  attributeTransformer,
  markdown,
}) => {
  const proseMirrorNodeFactories = createProseMirrorNodeFactories(
    schema,
    factorySpecs,
    attributeTransformer,
    markdown,
  );
  const state = new HastToProseMirrorConverterState();

  visitParents(tree, (hastNode, ancestors) => {
    const factory = findFactory(hastNode, ancestors, proseMirrorNodeFactories);

    if (!factory) {
      return SKIP;
    }

    const parent = findParent(ancestors, factory.parent);

    if (factory.wrapInParagraph) {
      /**
       * Modifying parameters is a bad practice. For performance reasons,
       * the author of the unist-util-visit-parents function recommends
       * modifying nodes in place to avoid traversing the Abstract Syntax
       * Tree more than once
       */
      // eslint-disable-next-line no-param-reassign
      hastNode.children = wrapInlineElements(
        removeEmptyTextNodes(hastNode.children),
        wrappableTags,
      );
    }

    factory.handle(state, hastNode, parent);

    return true;
  });

  return state.buildDoc();
};
