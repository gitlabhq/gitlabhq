import {
  sourceContentYAML as content,
  sourceContentTOML as tomlContent,
  sourceContentJSON as jsonContent,
  sourceContentHeaderYAML as yamlFrontMatter,
  sourceContentHeaderTOML as tomlFrontMatter,
  sourceContentHeaderJSON as jsonFrontMatter,
  sourceContentBody as body,
} from '../mock_data';

import parseSourceFile from '~/static_site_editor/services/parse_source_file';

describe('static_site_editor/services/parse_source_file', () => {
  const contentComplex = [content, content, content].join('');
  const complexBody = [body, content, content].join('');
  const edit = 'and more';
  const newContent = `${content} ${edit}`;
  const newContentComplex = `${contentComplex} ${edit}`;

  describe('unmodified front matter', () => {
    const yamlOptions = { frontMatterLanguage: 'yaml' };

    it.each`
      parsedSource                                                     | targetFrontMatter
      ${parseSourceFile(content)}                                      | ${yamlFrontMatter}
      ${parseSourceFile(contentComplex)}                               | ${yamlFrontMatter}
      ${parseSourceFile(content, yamlOptions)}                         | ${yamlFrontMatter}
      ${parseSourceFile(contentComplex, yamlOptions)}                  | ${yamlFrontMatter}
      ${parseSourceFile(tomlContent, { frontMatterLanguage: 'toml' })} | ${tomlFrontMatter}
      ${parseSourceFile(jsonContent, { frontMatterLanguage: 'json' })} | ${jsonFrontMatter}
    `(
      'returns $targetFrontMatter when frontMatter queried',
      ({ parsedSource, targetFrontMatter }) => {
        expect(parsedSource.frontMatter()).toBe(targetFrontMatter);
      },
    );
  });

  describe('unmodified content', () => {
    it.each`
      parsedSource
      ${parseSourceFile(content)}
      ${parseSourceFile(contentComplex)}
    `('returns false by default', ({ parsedSource }) => {
      expect(parsedSource.isModified()).toBe(false);
    });

    it.each`
      parsedSource                       | isBody       | target
      ${parseSourceFile(content)}        | ${undefined} | ${content}
      ${parseSourceFile(content)}        | ${false}     | ${content}
      ${parseSourceFile(content)}        | ${true}      | ${body}
      ${parseSourceFile(contentComplex)} | ${undefined} | ${contentComplex}
      ${parseSourceFile(contentComplex)} | ${false}     | ${contentComplex}
      ${parseSourceFile(contentComplex)} | ${true}      | ${complexBody}
    `(
      'returns only the $target content when the `isBody` parameter argument is $isBody',
      ({ parsedSource, isBody, target }) => {
        expect(parsedSource.content(isBody)).toBe(target);
      },
    );
  });

  describe('modified front matter', () => {
    const newYamlFrontMatter = '---\nnewKey: newVal\n---';
    const contentWithNewFrontMatter = content.replace(yamlFrontMatter, newYamlFrontMatter);
    const contentComplexWithNewFrontMatter = contentComplex.replace(
      yamlFrontMatter,
      newYamlFrontMatter,
    );

    it.each`
      parsedSource                       | targetContent
      ${parseSourceFile(content)}        | ${contentWithNewFrontMatter}
      ${parseSourceFile(contentComplex)} | ${contentComplexWithNewFrontMatter}
    `(
      'returns the correct front matter and modified content',
      ({ parsedSource, targetContent }) => {
        expect(parsedSource.frontMatter()).toBe(yamlFrontMatter);

        parsedSource.setFrontMatter(newYamlFrontMatter);

        expect(parsedSource.frontMatter()).toBe(newYamlFrontMatter);
        expect(parsedSource.content()).toBe(targetContent);
      },
    );
  });

  describe('modified content', () => {
    const newBody = `${body} ${edit}`;
    const newComplexBody = `${complexBody} ${edit}`;

    it.each`
      parsedSource                       | isModified | targetRaw            | targetBody
      ${parseSourceFile(content)}        | ${false}   | ${content}           | ${body}
      ${parseSourceFile(content)}        | ${true}    | ${newContent}        | ${newBody}
      ${parseSourceFile(contentComplex)} | ${false}   | ${contentComplex}    | ${complexBody}
      ${parseSourceFile(contentComplex)} | ${true}    | ${newContentComplex} | ${newComplexBody}
    `(
      'returns $isModified after a $targetRaw sync',
      ({ parsedSource, isModified, targetRaw, targetBody }) => {
        parsedSource.sync(targetRaw);

        expect(parsedSource.isModified()).toBe(isModified);
        expect(parsedSource.content()).toBe(targetRaw);
        expect(parsedSource.content(true)).toBe(targetBody);
      },
    );
  });
});
