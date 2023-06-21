import { validateTag, validationMessages } from '~/lib/utils/ref_validator';

describe('~/lib/utils/ref_validator', () => {
  describe('validateTag', () => {
    describe.each([
      ['foo'],
      ['FOO'],
      ['foo/a.lockx'],
      ['foo.123'],
      ['foo/123'],
      ['foo/bar/123'],
      ['foo.bar.123'],
      ['foo-bar_baz'],
      ['head'],
      ['"foo"-'],
      ['foo@bar'],
      ['\ud83e\udd8a'],
      ['ünicöde'],
      ['\x80}'],
    ])('tag with the name "%s"', (tagName) => {
      it('is valid', () => {
        const result = validateTag(tagName);
        expect(result.isValid).toBe(true);
        expect(result.validationErrors).toEqual([]);
      });
    });

    describe.each([
      ['  ', validationMessages.EmptyNameValidationMessage],

      ['refs/heads/tagName', validationMessages.DisallowedPrefixesValidationMessage],
      ['/foo', validationMessages.DisallowedPrefixesValidationMessage],
      ['-tagName', validationMessages.DisallowedPrefixesValidationMessage],

      ['HEAD', validationMessages.DisallowedNameValidationMessage],
      ['@', validationMessages.DisallowedNameValidationMessage],

      ['tag name with spaces', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag\\name', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag^name', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag..name', validationMessages.DisallowedSubstringsValidationMessage],
      ['..', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag?name', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag*name', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag[name', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag@{name', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag:name', validationMessages.DisallowedSubstringsValidationMessage],
      ['tag~name', validationMessages.DisallowedSubstringsValidationMessage],

      ['/', validationMessages.DisallowedSequenceEmptyValidationMessage],
      ['//', validationMessages.DisallowedSequenceEmptyValidationMessage],
      ['foo//123', validationMessages.DisallowedSequenceEmptyValidationMessage],

      ['.', validationMessages.DisallowedSequencePrefixesValidationMessage],
      ['/./', validationMessages.DisallowedSequencePrefixesValidationMessage],
      ['./.', validationMessages.DisallowedSequencePrefixesValidationMessage],
      ['.tagName', validationMessages.DisallowedSequencePrefixesValidationMessage],
      ['tag/.Name', validationMessages.DisallowedSequencePrefixesValidationMessage],
      ['foo/.123/bar', validationMessages.DisallowedSequencePrefixesValidationMessage],

      ['foo.', validationMessages.DisallowedSequencePostfixesValidationMessage],
      ['a.lock', validationMessages.DisallowedSequencePostfixesValidationMessage],
      ['foo/a.lock', validationMessages.DisallowedSequencePostfixesValidationMessage],
      ['foo/a.lock/b', validationMessages.DisallowedSequencePostfixesValidationMessage],
      ['foo.123.', validationMessages.DisallowedSequencePostfixesValidationMessage],

      ['foo/', validationMessages.DisallowedPostfixesValidationMessage],
    ])('tag with name "%s"', (tagName, validationMessage) => {
      it(`should be invalid with validation message "${validationMessage}"`, () => {
        const result = validateTag(tagName);
        expect(result.isValid).toBe(false);
        expect(result.validationErrors).toContain(validationMessage);
      });
    });

    // NOTE: control characters cannot be used in test names because they cause test report XML parsing errors
    describe.each([
      [
        'control-character x7f',
        'control-character\x7f',
        validationMessages.ControlCharactersValidationMessage,
      ],
      [
        'control-character x15',
        'control-character\x15',
        validationMessages.ControlCharactersValidationMessage,
      ],
    ])('tag with name "%s"', (_, tagName, validationMessage) => {
      it(`should be invalid with validation message "${validationMessage}"`, () => {
        const result = validateTag(tagName);
        expect(result.isValid).toBe(false);
        expect(result.validationErrors).toContain(validationMessage);
      });
    });
  });
});
