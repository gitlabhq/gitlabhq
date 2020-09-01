import getFrontMatterLanguageDefinition from '~/static_site_editor/services/parse_source_file_language_support';

describe('static_site_editor/services/parse_source_file_language_support', () => {
  describe('getFrontMatterLanguageDefinition', () => {
    it.each`
      languageName
      ${'yaml'}
      ${'toml'}
      ${'json'}
      ${'abcd'}
    `('returns $hasMatch when provided $languageName', ({ languageName }) => {
      try {
        const definition = getFrontMatterLanguageDefinition(languageName);
        expect(definition.name).toBe(languageName);
      } catch (error) {
        expect(error.message).toBe(`Unsupported front matter language: ${languageName}`);
      }
    });
  });
});
