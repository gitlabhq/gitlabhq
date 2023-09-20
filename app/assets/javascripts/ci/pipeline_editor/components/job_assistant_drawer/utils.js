import { isEmpty, isObject, isArray, isString, reject, omitBy, mapValues, map, trim } from 'lodash';
import {
  JOB_RULES_WHEN,
  SECONDS_MULTIPLE_MAP,
} from '~/ci/pipeline_editor/components/job_assistant_drawer/constants';

const isEmptyValue = (val) => (isObject(val) || isString(val)) && isEmpty(val);
const trimText = (val) => (isString(val) ? trim(val) : val);

export const removeEmptyObj = (obj) => {
  if (isArray(obj)) {
    return reject(map(obj, removeEmptyObj), isEmptyValue);
  }
  if (isObject(obj)) {
    return omitBy(mapValues(obj, removeEmptyObj), isEmptyValue);
  }
  return obj;
};

export const trimFields = (data) => {
  if (isArray(data)) {
    return data.map(trimFields);
  }
  if (isObject(data)) {
    return mapValues(data, trimFields);
  }
  return trimText(data);
};

export const validateEmptyValue = (value) => {
  return trim(value) !== '';
};

export const validateStartIn = (when, startIn) => {
  const hasNoValue = when !== JOB_RULES_WHEN.delayed.value;
  if (hasNoValue) {
    return true;
  }

  let [startInNumber, startInUnit] = startIn.split(' ');

  startInNumber = Number(startInNumber);
  if (!Number.isInteger(startInNumber)) {
    return false;
  }

  const isPlural = startInUnit.slice(-1) === 's';
  if (isPlural) {
    startInUnit = startInUnit.slice(0, -1);
  }

  const multiple = SECONDS_MULTIPLE_MAP[startInUnit];

  return startInNumber * multiple >= 1 && startInNumber * multiple <= SECONDS_MULTIPLE_MAP.week;
};
