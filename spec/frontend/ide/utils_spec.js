import { languages } from 'monaco-editor';
import { setDiagnosticsOptions as yamlDiagnosticsOptions } from 'monaco-yaml';
import { registerLanguages, registerSchema } from '~/ide/utils';

describe('WebIDE utils', () => {
  describe('registerLanguages', () => {
    let langs;

    beforeEach(() => {
      langs = [
        {
          id: 'html',
          extensions: ['.html'],
          conf: { comments: { blockComment: ['<!--', '-->'] } },
          language: { tokenizer: {} },
        },
        {
          id: 'css',
          extensions: ['.css'],
          conf: { comments: { blockComment: ['/*', '*/'] } },
          language: { tokenizer: {} },
        },
        {
          id: 'js',
          extensions: ['.js'],
          conf: { comments: { blockComment: ['/*', '*/'] } },
          language: { tokenizer: {} },
        },
      ];

      jest.spyOn(languages, 'register').mockImplementation(() => {});
      jest.spyOn(languages, 'setMonarchTokensProvider').mockImplementation(() => {});
      jest.spyOn(languages, 'setLanguageConfiguration').mockImplementation(() => {});
    });

    it('registers all the passed languages with Monaco', () => {
      registerLanguages(...langs);

      expect(languages.register.mock.calls).toEqual([
        [
          {
            conf: { comments: { blockComment: ['/*', '*/'] } },
            extensions: ['.css'],
            id: 'css',
            language: { tokenizer: {} },
          },
        ],
        [
          {
            conf: { comments: { blockComment: ['/*', '*/'] } },
            extensions: ['.js'],
            id: 'js',
            language: { tokenizer: {} },
          },
        ],
        [
          {
            conf: { comments: { blockComment: ['<!--', '-->'] } },
            extensions: ['.html'],
            id: 'html',
            language: { tokenizer: {} },
          },
        ],
      ]);

      expect(languages.setMonarchTokensProvider.mock.calls).toEqual([
        ['css', { tokenizer: {} }],
        ['js', { tokenizer: {} }],
        ['html', { tokenizer: {} }],
      ]);

      expect(languages.setLanguageConfiguration.mock.calls).toEqual([
        ['css', { comments: { blockComment: ['/*', '*/'] } }],
        ['js', { comments: { blockComment: ['/*', '*/'] } }],
        ['html', { comments: { blockComment: ['<!--', '-->'] } }],
      ]);
    });
  });

  describe('registerSchema', () => {
    let schema;

    beforeEach(() => {
      schema = {
        uri: 'http://myserver/foo-schema.json',
        fileMatch: ['*'],
        schema: {
          id: 'http://myserver/foo-schema.json',
          type: 'object',
          properties: {
            p1: { enum: ['v1', 'v2'] },
            p2: { $ref: 'http://myserver/bar-schema.json' },
          },
        },
      };

      jest.spyOn(languages.json.jsonDefaults, 'setDiagnosticsOptions');
    });

    it('registers the given schemas with monaco for both json and yaml languages', () => {
      registerSchema(schema);

      expect(languages.json.jsonDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
        expect.objectContaining({ schemas: [schema] }),
      );
      expect(yamlDiagnosticsOptions).toHaveBeenCalledWith(
        expect.objectContaining({ schemas: [schema] }),
      );
    });
  });
});
