export const Types = {
  FIELD_NAME: 'field_name',
  STRING: 'string',
  COLLECTION: 'collection',
  FUNCTION_CALL: 'function_call',
};

export const fieldName = (name) => ({ type: Types.FIELD_NAME, value: name });
export const string = (value) => ({ type: Types.STRING, value });
export const functionCall = (name, args) => ({ type: Types.FUNCTION_CALL, name, args });
export const collection = (...values) => ({ type: Types.COLLECTION, value: values });
