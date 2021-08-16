import { NEW_NAME_FIELD } from './constants';

export function isNameValid(group, validationRegex) {
  return validationRegex.test(group.import_target[NEW_NAME_FIELD]);
}

export function getInvalidNameValidationMessage(group) {
  return group.validation_errors.find(({ field }) => field === NEW_NAME_FIELD)?.message;
}

export function isInvalid(group, validationRegex) {
  return Boolean(!isNameValid(group, validationRegex) || getInvalidNameValidationMessage(group));
}
