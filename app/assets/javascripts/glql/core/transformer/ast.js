import { uniqueId } from 'lodash';
import { __, sprintf } from '~/locale';
import { toSentenceCase } from '../../utils/common';
import * as ast from '../parser/ast';
import { getFieldAlias } from './field_aliases';
import { getFunction } from './functions';

const getValue = (astNode) => {
  if (astNode.type === ast.Types.COLLECTION) return astNode.value.map(getValue);
  if (astNode.type === ast.Types.FIELD_NAME) return getFieldAlias(astNode.value) || astNode.value;
  if (astNode.type === ast.Types.FUNCTION_CALL) {
    const fn = getFunction(astNode.name);
    if (!fn) throw new Error(sprintf(__('Unknown function: %{name}'), { name: astNode.name }));
    return fn.getFieldName(...getValue(astNode.args));
  }

  return astNode.value;
};

export const transformAstToDisplayFields = (astNode) => {
  if (astNode.type === ast.Types.COLLECTION) return astNode.value.map(transformAstToDisplayFields);
  if (astNode.type === ast.Types.FIELD_NAME) {
    const fieldName = getValue(astNode);
    return { key: fieldName, label: toSentenceCase(astNode.value), name: fieldName };
  }
  if (astNode.type === ast.Types.FUNCTION_CALL) {
    const args = getValue(astNode.args);
    const key = uniqueId(`${astNode.name}_${args.join('_')}_`);
    const fn = getFunction(astNode.name);
    return {
      key,
      label: fn.getFieldLabel(...args),
      name: getValue(astNode),
      transform: fn.getTransformer(key, ...args),
    };
  }

  throw new Error(sprintf(__('Unknown value type: %{type}'), { type: astNode.type }));
};
