/**
 * This file adds a merge function to be used with a yaml Document as defined by
 * the yaml@2.x package: https://eemeli.org/yaml/#yaml
 *
 * Ultimately, this functionality should be merged upstream into the package,
 * track the progress of that effort at https://github.com/eemeli/yaml/pull/347
 * */

import { visit, Scalar, isCollection, isDocument, isScalar, isNode, isMap, isSeq } from 'yaml';

function getPath(ancestry) {
  return ancestry.reduce((p, { key }) => {
    return key !== undefined ? [...p, key.value] : p;
  }, []);
}

function getFirstChildNode(collection) {
  let firstChildKey;
  if (isSeq(collection)) {
    return collection.items.find((i) => isNode(i));
  }
  if (isMap(collection)) {
    firstChildKey = collection.items[0]?.key;
    if (!firstChildKey) return undefined;
    return isScalar(firstChildKey) ? firstChildKey : new Scalar(firstChildKey);
  }
  throw Error(
    `Cannot identify a child Node for Collection. Expecting a YAMLMap or a YAMLSeq. Got: ${collection}`,
  );
}

function moveMetaPropsToFirstChildNode(collection) {
  const firstChildNode = getFirstChildNode(collection);
  const { comment, commentBefore, spaceBefore } = collection;
  if (!(comment || commentBefore || spaceBefore)) return;
  if (!firstChildNode)
    throw new Error('Cannot move meta properties to a child of an empty Collection'); // eslint-disable-line @gitlab/require-i18n-strings
  Object.assign(firstChildNode, { comment, commentBefore, spaceBefore });
  Object.assign(collection, {
    comment: undefined,
    commentBefore: undefined,
    spaceBefore: undefined,
  });
}

function assert(isTypeFn, node, path) {
  if (![isSeq, isMap].includes(isTypeFn)) {
    throw new Error('assert() can only be used with isSeq() and isMap()');
  }
  const expectedTypeName = isTypeFn === isSeq ? 'YAMLSeq' : 'YAMLMap'; // eslint-disable-line @gitlab/require-i18n-strings
  if (!isTypeFn(node)) {
    const type = node?.constructor?.name || typeof node;
    throw new Error(
      `Type conflict at "${path.join(
        '.',
      )}": Destination node is of type ${type}, the node to be merged is of type ${expectedTypeName}.`,
    );
  }
}

function mergeCollection(target, node, path) {
  // In case both the source and the target node have comments or spaces
  // We'll move them to their first child so they do not conflict
  moveMetaPropsToFirstChildNode(node);
  if (target.hasIn(path)) {
    const targetNode = target.getIn(path, true);
    assert(isSeq(node) ? isSeq : isMap, targetNode, path);
    moveMetaPropsToFirstChildNode(targetNode);
  }
}

function mergePair(target, node, path) {
  if (!isScalar(node.value)) return undefined;
  if (target.hasIn([...path, node.key.value])) {
    target.setIn(path, node);
  } else {
    target.addIn(path, node);
  }
  return visit.SKIP;
}

function getVisitorFn(target, options) {
  return {
    Map: (_, node, ancestors) => {
      mergeCollection(target, node, getPath(ancestors));
    },
    Pair: (_, node, ancestors) => {
      mergePair(target, node, getPath(ancestors));
    },
    Seq: (_, node, ancestors) => {
      const path = getPath(ancestors);
      mergeCollection(target, node, path);
      if (options.onSequence === 'replace') {
        target.setIn(path, node);
        return visit.SKIP;
      }
      node.items.forEach((item) => target.addIn(path, item));
      return visit.SKIP;
    },
  };
}

/** Merge another collection into this */
export function merge(target, source, options = {}) {
  const opt = {
    onSequence: 'replace',
    ...options,
  };
  const sourceNode = target.createNode(isDocument(source) ? source.contents : source);
  if (!isCollection(sourceNode)) {
    const type = source?.constructor?.name || typeof source;
    throw new Error(`Cannot merge type "${type}", expected a Collection`);
  }
  if (!isCollection(target.contents)) {
    // If the target doc is empty add the source to it directly
    Object.assign(target, { contents: sourceNode });
    return;
  }
  visit(sourceNode, getVisitorFn(target, opt));
}
