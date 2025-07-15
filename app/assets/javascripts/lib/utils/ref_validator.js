import { __, sprintf } from '~/locale';

// this service validates tagName agains git ref format.
// the git spec can be found here: https://git-scm.com/docs/git-check-ref-format#_description

// the ruby counterpart of the validator is here:
// lib/gitlab/git_ref_validator.rb

const EXPANDED_PREFIXES = ['refs/heads/', 'refs/remotes/', 'refs/tags'];
const DISALLOWED_PREFIXES = ['-', '/'];
const DISALLOWED_POSTFIXES = ['/'];
const DISALLOWED_NAMES = ['HEAD', '@'];
const DISALLOWED_SUBSTRINGS = [' ', '\\', '~', ':', '..', '^', '?', '*', '[', '@{'];
const DISALLOWED_SEQUENCE_POSTFIXES = ['.lock', '.'];
const DISALLOWED_SEQUENCE_PREFIXES = ['.'];

// eslint-disable-next-line no-control-regex
const CONTROL_CHARACTERS_REGEX = /[\x00-\x19\x7f]/;

const toReadableString = (array) => array.map((item) => `"${item}"`).join(', ');

const DisallowedPrefixesValidationMessage = sprintf(
  __('Tag name should not start with %{prefixes}'),
  {
    prefixes: toReadableString([...EXPANDED_PREFIXES, ...DISALLOWED_PREFIXES]),
  },
  false,
);

const DisallowedPostfixesValidationMessage = sprintf(
  __('Tag name should not end with %{postfixes}'),
  { postfixes: toReadableString(DISALLOWED_POSTFIXES) },
  false,
);

const DisallowedNameValidationMessage = sprintf(
  __('Tag name cannot be one of the following: %{names}'),
  { names: toReadableString(DISALLOWED_NAMES) },
  false,
);

const EmptyNameValidationMessage = __('Tag name should not be empty');

const DisallowedSubstringsValidationMessage = sprintf(
  __('Tag name should not contain any of the following: %{substrings}'),
  { substrings: toReadableString(DISALLOWED_SUBSTRINGS) },
  false,
);

const DisallowedSequenceEmptyValidationMessage = __(
  `No slash-separated tag name component can be empty`,
);

const DisallowedSequencePrefixesValidationMessage = sprintf(
  __('No slash-separated component can begin with %{sequencePrefixes}'),
  { sequencePrefixes: toReadableString(DISALLOWED_SEQUENCE_PREFIXES) },
  false,
);

const DisallowedSequencePostfixesValidationMessage = sprintf(
  __('No slash-separated component can end with %{sequencePostfixes}'),
  { sequencePostfixes: toReadableString(DISALLOWED_SEQUENCE_POSTFIXES) },
  false,
);

const ControlCharactersValidationMessage = __('Tag name should not contain any control characters');

export const validationMessages = {
  EmptyNameValidationMessage,
  DisallowedPrefixesValidationMessage,
  DisallowedPostfixesValidationMessage,
  DisallowedNameValidationMessage,
  DisallowedSubstringsValidationMessage,
  DisallowedSequenceEmptyValidationMessage,
  DisallowedSequencePrefixesValidationMessage,
  DisallowedSequencePostfixesValidationMessage,
  ControlCharactersValidationMessage,
};

export class ValidationResult {
  isValid = true;
  validationErrors = [];

  addValidationError = (errorMessage) => {
    this.isValid = false;
    this.validationErrors.push(errorMessage);
  };
}

export const validateTag = (refName) => {
  if (typeof refName !== 'string') {
    throw new Error('refName argument must be a string');
  }

  const validationResult = new ValidationResult();

  if (!refName || refName.trim() === '') {
    validationResult.addValidationError(EmptyNameValidationMessage);
    return validationResult;
  }

  if (CONTROL_CHARACTERS_REGEX.test(refName)) {
    validationResult.addValidationError(ControlCharactersValidationMessage);
  }

  if (DISALLOWED_NAMES.some((name) => name === refName)) {
    validationResult.addValidationError(DisallowedNameValidationMessage);
  }

  if ([...EXPANDED_PREFIXES, ...DISALLOWED_PREFIXES].some((prefix) => refName.startsWith(prefix))) {
    validationResult.addValidationError(DisallowedPrefixesValidationMessage);
  }

  if (DISALLOWED_POSTFIXES.some((postfix) => refName.endsWith(postfix))) {
    validationResult.addValidationError(DisallowedPostfixesValidationMessage);
  }

  if (DISALLOWED_SUBSTRINGS.some((substring) => refName.includes(substring))) {
    validationResult.addValidationError(DisallowedSubstringsValidationMessage);
  }

  const refNameParts = refName.split('/');

  if (refNameParts.some((part) => part === '')) {
    validationResult.addValidationError(DisallowedSequenceEmptyValidationMessage);
  }

  if (
    refNameParts.some((part) =>
      DISALLOWED_SEQUENCE_PREFIXES.some((prefix) => part.startsWith(prefix)),
    )
  ) {
    validationResult.addValidationError(DisallowedSequencePrefixesValidationMessage);
  }

  if (
    refNameParts.some((part) =>
      DISALLOWED_SEQUENCE_POSTFIXES.some((postfix) => part.endsWith(postfix)),
    )
  ) {
    validationResult.addValidationError(DisallowedSequencePostfixesValidationMessage);
  }

  return validationResult;
};
