import { languages } from 'monaco-editor';
import {
  isTextFile,
  registerLanguages,
  registerSchema,
  trimPathComponents,
  trimTrailingWhitespace,
  getPathParents,
  getPathParent,
  readFileAsDataURL,
  addNumericSuffix,
} from '~/ide/utils';

describe('WebIDE utils', () => {
  describe('isTextFile', () => {
    it.each`
      mimeType        | name        | type        | result
      ${'image/png'}  | ${'my.png'} | ${'binary'} | ${false}
      ${'IMAGE/PNG'}  | ${'my.png'} | ${'binary'} | ${false}
      ${'text/plain'} | ${'my.txt'} | ${'text'}   | ${true}
      ${'TEXT/PLAIN'} | ${'my.txt'} | ${'text'}   | ${true}
    `('returns $result for known $type types', ({ mimeType, name, result }) => {
      expect(isTextFile({ content: 'file content', mimeType, name })).toBe(result);
    });

    it.each`
      content                                   | mimeType                      | name
      ${'{"éêė":"value"}'}                      | ${'application/json'}         | ${'my.json'}
      ${'{"éêė":"value"}'}                      | ${'application/json'}         | ${'.tsconfig'}
      ${'SELECT "éêė" from tablename'}          | ${'application/sql'}          | ${'my.sql'}
      ${'{"éêė":"value"}'}                      | ${'application/json'}         | ${'MY.JSON'}
      ${'SELECT "éêė" from tablename'}          | ${'application/sql'}          | ${'MY.SQL'}
      ${'var code = "something"'}               | ${'application/javascript'}   | ${'Gruntfile'}
      ${'MAINTAINER Александр "a21283@me.com"'} | ${'application/octet-stream'} | ${'dockerfile'}
    `(
      'returns true for file extensions that Monaco supports syntax highlighting for',
      ({ content, mimeType, name }) => {
        expect(isTextFile({ content, mimeType, name })).toBe(true);
      },
    );

    it('returns false if filename is same as the expected extension', () => {
      expect(
        isTextFile({
          name: 'sql',
          content: 'SELECT "éêė" from tablename',
          mimeType: 'application/sql',
        }),
      ).toBeFalsy();
    });

    it('returns true for ASCII only content for unknown types', () => {
      expect(
        isTextFile({
          name: 'hello.mytype',
          content: 'plain text',
          mimeType: 'application/x-new-type',
        }),
      ).toBeTruthy();
    });

    it('returns false for non-ASCII content for unknown types', () => {
      expect(
        isTextFile({
          name: 'my.random',
          content: '{"éêė":"value"}',
          mimeType: 'application/octet-stream',
        }),
      ).toBeFalsy();
    });

    it.each`
      name            | result
      ${'myfile.txt'} | ${true}
      ${'Dockerfile'} | ${true}
      ${'img.png'}    | ${false}
      ${'abc.js'}     | ${true}
      ${'abc.random'} | ${false}
      ${'image.jpeg'} | ${false}
    `('returns $result for $filename when no content or mimeType is passed', ({ name, result }) => {
      expect(isTextFile({ name })).toBe(result);
    });

    it('returns true if content is empty string but false if content is not passed', () => {
      expect(isTextFile({ name: 'abc.dat' })).toBe(false);
      expect(isTextFile({ name: 'abc.dat', content: '' })).toBe(true);
      expect(isTextFile({ name: 'abc.dat', content: '  ' })).toBe(true);
    });
  });

  describe('trimPathComponents', () => {
    it.each`
      input                           | output
      ${'example path '}              | ${'example path'}
      ${'p/somefile '}                | ${'p/somefile'}
      ${'p /somefile '}               | ${'p/somefile'}
      ${'p/ somefile '}               | ${'p/somefile'}
      ${' p/somefile '}               | ${'p/somefile'}
      ${'p/somefile  .md'}            | ${'p/somefile  .md'}
      ${'path / to / some/file.doc '} | ${'path/to/some/file.doc'}
    `('trims all path components in path: "$input"', ({ input, output }) => {
      expect(trimPathComponents(input)).toEqual(output);
    });
  });

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
      jest.spyOn(languages.yaml.yamlDefaults, 'setDiagnosticsOptions');
    });

    it('registers the given schemas with monaco for both json and yaml languages', () => {
      registerSchema(schema);

      expect(languages.json.jsonDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
        expect.objectContaining({ schemas: [schema] }),
      );
      expect(languages.yaml.yamlDefaults.setDiagnosticsOptions).toHaveBeenCalledWith(
        expect.objectContaining({ schemas: [schema] }),
      );
    });
  });

  describe('trimTrailingWhitespace', () => {
    it.each`
      input                                                            | output
      ${'text     \n   more text   \n'}                                | ${'text\n   more text\n'}
      ${'text     \n   more text   \n\n   \n'}                         | ${'text\n   more text\n\n\n'}
      ${'text  \t\t   \n   more text   \n\t\ttext\n   \n\t\t'}         | ${'text\n   more text\n\t\ttext\n\n'}
      ${'text     \r\n   more text   \r\n'}                            | ${'text\r\n   more text\r\n'}
      ${'text     \r\n   more text   \r\n\r\n   \r\n'}                 | ${'text\r\n   more text\r\n\r\n\r\n'}
      ${'text  \t\t   \r\n   more text   \r\n\t\ttext\r\n   \r\n\t\t'} | ${'text\r\n   more text\r\n\t\ttext\r\n\r\n'}
    `("trims trailing whitespace in each line of file's contents: $input", ({ input, output }) => {
      expect(trimTrailingWhitespace(input)).toBe(output);
    });
  });

  describe('getPathParents', () => {
    it.each`
      path                                  | parents
      ${'foo/bar/baz/index.md'}             | ${['foo/bar/baz', 'foo/bar', 'foo']}
      ${'foo/bar/baz'}                      | ${['foo/bar', 'foo']}
      ${'index.md'}                         | ${[]}
      ${'path with/spaces to/something.md'} | ${['path with/spaces to', 'path with']}
    `('gets all parent directory names for path: $path', ({ path, parents }) => {
      expect(getPathParents(path)).toEqual(parents);
    });

    it.each`
      path                      | depth | parents
      ${'foo/bar/baz/index.md'} | ${0}  | ${[]}
      ${'foo/bar/baz/index.md'} | ${1}  | ${['foo/bar/baz']}
      ${'foo/bar/baz/index.md'} | ${2}  | ${['foo/bar/baz', 'foo/bar']}
      ${'foo/bar/baz/index.md'} | ${3}  | ${['foo/bar/baz', 'foo/bar', 'foo']}
      ${'foo/bar/baz/index.md'} | ${4}  | ${['foo/bar/baz', 'foo/bar', 'foo']}
    `('gets only the immediate $depth parents if when depth=$depth', ({ path, depth, parents }) => {
      expect(getPathParents(path, depth)).toEqual(parents);
    });
  });

  describe('getPathParent', () => {
    it.each`
      path                                  | parents
      ${'foo/bar/baz/index.md'}             | ${'foo/bar/baz'}
      ${'foo/bar/baz'}                      | ${'foo/bar'}
      ${'index.md'}                         | ${undefined}
      ${'path with/spaces to/something.md'} | ${'path with/spaces to'}
    `('gets the immediate parent for path: $path', ({ path, parents }) => {
      expect(getPathParent(path)).toEqual(parents);
    });
  });

  describe('readFileAsDataURL', () => {
    it('reads a file and returns its output as a data url', () => {
      const file = new File(['foo'], 'foo.png', { type: 'image/png' });

      return readFileAsDataURL(file).then((contents) => {
        expect(contents).toBe('data:image/png;base64,Zm9v');
      });
    });
  });

  /*
   *  hello-2425 -> hello-2425
   *  hello.md -> hello-1.md
   *  hello_2.md -> hello_3.md
   *  hello_ -> hello_1
   *  main-patch-22432 -> main-patch-22433
   *  patch_332 -> patch_333
   */

  describe('addNumericSuffix', () => {
    it.each`
      input                 | output
      ${'hello'}            | ${'hello-1'}
      ${'hello2'}           | ${'hello-3'}
      ${'hello.md'}         | ${'hello-1.md'}
      ${'hello_2.md'}       | ${'hello_3.md'}
      ${'hello_'}           | ${'hello_1'}
      ${'main-patch-22432'} | ${'main-patch-22433'}
      ${'patch_332'}        | ${'patch_333'}
    `('adds a numeric suffix to a given filename/branch name: $input', ({ input, output }) => {
      expect(addNumericSuffix(input)).toBe(output);
    });

    it.each`
      input                 | output
      ${'hello'}            | ${'hello-39135'}
      ${'hello2'}           | ${'hello-39135'}
      ${'hello.md'}         | ${'hello-39135.md'}
      ${'hello_2.md'}       | ${'hello_39135.md'}
      ${'hello_'}           | ${'hello_39135'}
      ${'main-patch-22432'} | ${'main-patch-39135'}
      ${'patch_332'}        | ${'patch_39135'}
    `('adds a random suffix if randomize=true is passed for name: $input', ({ input, output }) => {
      jest.spyOn(Math, 'random').mockReturnValue(0.391352525);

      expect(addNumericSuffix(input, true)).toBe(output);
    });
  });
});
