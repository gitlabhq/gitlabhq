import { TYPE_FALLBACK } from './constants';

export const getValueByEventTarget = (map, event) => {
  const {
    target: { type: targetType, issue_type: issueType },
  } = event;

  return map[issueType || targetType] || map[TYPE_FALLBACK];
};
