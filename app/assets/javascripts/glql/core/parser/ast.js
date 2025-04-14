import { __, sprintf } from '~/locale';

export const Types = {
  FIELD_NAME: 'field_name',
  STRING: 'string',
  COLLECTION: 'collection',
  FUNCTION_CALL: 'function_call',
};

class AstNode {
  constructor(type, { ...data }) {
    this.type = type;
    Object.assign(this, data);
  }

  withAlias(alias) {
    if (![Types.FIELD_NAME, Types.FUNCTION_CALL].includes(this.type))
      throw new Error(sprintf(__('Unsupported node type for alias: %{type}'), { type: this.type }));
    if (alias.type !== Types.STRING) throw new Error(__('Field alias must be of type `String`.'));

    this.alias = alias;
    return this;
  }
}

export const fieldName = (name) => new AstNode(Types.FIELD_NAME, { value: name });
export const string = (value) => new AstNode(Types.STRING, { value });
export const functionCall = (name, args) => new AstNode(Types.FUNCTION_CALL, { name, args });
export const collection = (...values) => new AstNode(Types.COLLECTION, { value: values });
