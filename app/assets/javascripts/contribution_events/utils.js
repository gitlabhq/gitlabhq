import { TYPE_FALLBACK, VARIANT_AVATAR, VARIANT_DEFAULT } from './constants';

export const getValueByEventTarget = (map, event) => {
  const {
    target: { type: targetType, issue_type: issueType },
  } = event;

  return map[issueType || targetType] || map[TYPE_FALLBACK];
};

export const isValidVariant = (value) => [VARIANT_AVATAR, VARIANT_DEFAULT].includes(value);
