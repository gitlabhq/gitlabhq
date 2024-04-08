import { STATUSES } from '../constants';
import { NEW_NAME_FIELD } from './constants';

export function isNameValid(importTarget, validationRegex) {
  return validationRegex.test(importTarget[NEW_NAME_FIELD]);
}

export function validationMessageFor(importTarget, field) {
  return importTarget?.validationErrors?.find(({ field: fieldName }) => fieldName === field)
    ?.message;
}

export function isFinished(group) {
  return [STATUSES.FINISHED, STATUSES.FAILED, STATUSES.TIMEOUT].includes(group.progress?.status);
}

export function isAvailableForImport(group) {
  return !group.progress || isFinished(group);
}

export function isProjectCreationAllowed(group = {}) {
  // When "No parent" is selected
  if (group.fullPath === '') {
    return true;
  }

  return Boolean(group.projectCreationLevel) && group.projectCreationLevel !== 'noone';
}

export function isSameTarget(importTarget) {
  return (target) =>
    target !== importTarget &&
    target.newName.toLowerCase() === importTarget.newName.toLowerCase() &&
    target.targetNamespace.id === importTarget.targetNamespace.id;
}
