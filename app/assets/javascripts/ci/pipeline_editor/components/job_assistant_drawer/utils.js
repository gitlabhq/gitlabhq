import { isEmpty, isObject, isArray, isString, reject, omitBy, mapValues, map, trim } from 'lodash';

const isEmptyValue = (val) => (isObject(val) || isString(val)) && isEmpty(val);
const trimText = (val) => (isString(val) ? trim(val) : val);

export const removeEmptyObj = (obj) => {
  if (isArray(obj)) {
    return reject(map(obj, removeEmptyObj), isEmptyValue);
  } else if (isObject(obj)) {
    return omitBy(mapValues(obj, removeEmptyObj), isEmptyValue);
  }
  return obj;
};

export const trimFields = (data) => {
  if (isArray(data)) {
    return data.map(trimFields);
  } else if (isObject(data)) {
    return mapValues(data, trimFields);
  }
  return trimText(data);
};
