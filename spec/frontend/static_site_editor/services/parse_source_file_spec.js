import {
  sourceContent as content,
  sourceContentHeader as header,
  sourceContentSpacing as spacing,
  sourceContentBody as body,
} from '../mock_data';

import parseSourceFile from '~/static_site_editor/services/parse_source_file';

describe('parseSourceFile', () => {
  const contentSimple = content;
  const contentComplex = [content, content, content].join('');

  describe('the editable shape and its expected values', () => {
    it.each`
      sourceContent     | sourceHeader | sourceSpacing | sourceBody                           | desc
      ${contentSimple}  | ${header}    | ${spacing}    | ${body}                              | ${'extracts header'}
      ${contentComplex} | ${header}    | ${spacing}    | ${[body, content, content].join('')} | ${'extracts body'}
    `('$desc', ({ sourceContent, sourceHeader, sourceSpacing, sourceBody }) => {
      const { editable } = parseSourceFile(sourceContent);

      expect(editable).toMatchObject({
        raw: sourceContent,
        header: sourceHeader,
        spacing: sourceSpacing,
        body: sourceBody,
      });
    });

    it('returns the same front matter regardless of front matter duplication', () => {
      const parsedSourceSimple = parseSourceFile(contentSimple);
      const parsedSourceComplex = parseSourceFile(contentComplex);

      expect(parsedSourceSimple.editable.header).toBe(parsedSourceComplex.editable.header);
    });
  });

  describe('editable body to raw content default and changes', () => {
    it.each`
      sourceContent     | desc
      ${contentSimple}  | ${'returns false by default for both raw and body'}
      ${contentComplex} | ${'returns false by default for both raw and body'}
    `('$desc', ({ sourceContent }) => {
      const parsedSource = parseSourceFile(sourceContent);

      expect(parsedSource.isModifiedRaw()).toBe(false);
      expect(parsedSource.isModifiedBody()).toBe(false);
    });

    it.each`
      sourceContent     | editableKey | syncKey       | isModifiedKey       | desc
      ${contentSimple}  | ${'body'}   | ${'syncRaw'}  | ${'isModifiedRaw'}  | ${'returns true after modification and sync'}
      ${contentSimple}  | ${'raw'}    | ${'syncBody'} | ${'isModifiedBody'} | ${'returns true after modification and sync'}
      ${contentComplex} | ${'body'}   | ${'syncRaw'}  | ${'isModifiedRaw'}  | ${'returns true after modification and sync'}
      ${contentComplex} | ${'raw'}    | ${'syncBody'} | ${'isModifiedBody'} | ${'returns true after modification and sync'}
    `('$desc', ({ sourceContent, editableKey, syncKey, isModifiedKey }) => {
      const parsedSource = parseSourceFile(sourceContent);
      parsedSource.editable[editableKey] += 'Added content';
      parsedSource[syncKey]();

      expect(parsedSource[isModifiedKey]()).toBe(true);
    });
  });
});
