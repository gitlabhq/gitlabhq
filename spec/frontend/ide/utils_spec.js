import {
  isTextFile,
  registerLanguages,
  trimPathComponents,
  insertFinalNewline,
  trimTrailingWhitespace,
  getPathParents,
  getPathParent,
  readFileAsDataURL,
} from '~/ide/utils';
import { languages } from 'monaco-editor';

describe('WebIDE utils', () => {
  describe('isTextFile', () => {
    it('returns false for known binary types', () => {
      expect(isTextFile('file content', 'image/png', 'my.png')).toBeFalsy();
      // mime types are case insensitive
      expect(isTextFile('file content', 'IMAGE/PNG', 'my.png')).toBeFalsy();
    });

    it('returns true for known text types', () => {
      expect(isTextFile('file content', 'text/plain', 'my.txt')).toBeTruthy();
      // mime types are case insensitive
      expect(isTextFile('file content', 'TEXT/PLAIN', 'my.txt')).toBeTruthy();
    });

    it('returns true for file extensions that Monaco supports syntax highlighting for', () => {
      // test based on both MIME and extension
      expect(isTextFile('{"éêė":"value"}', 'application/json', 'my.json')).toBeTruthy();
      expect(isTextFile('{"éêė":"value"}', 'application/json', '.tsconfig')).toBeTruthy();
      expect(isTextFile('SELECT "éêė" from tablename', 'application/sql', 'my.sql')).toBeTruthy();
    });

    it('returns true even irrespective of whether the mimes, extensions or file names are lowercase or upper case', () => {
      expect(isTextFile('{"éêė":"value"}', 'application/json', 'MY.JSON')).toBeTruthy();
      expect(isTextFile('SELECT "éêė" from tablename', 'application/sql', 'MY.SQL')).toBeTruthy();
      expect(
        isTextFile('var code = "something"', 'application/javascript', 'Gruntfile'),
      ).toBeTruthy();
      expect(
        isTextFile(
          'MAINTAINER Александр "alexander11354322283@me.com"',
          'application/octet-stream',
          'dockerfile',
        ),
      ).toBeTruthy();
    });

    it('returns false if filename is same as the expected extension', () => {
      expect(isTextFile('SELECT "éêė" from tablename', 'application/sql', 'sql')).toBeFalsy();
    });

    it('returns true for ASCII only content for unknown types', () => {
      expect(isTextFile('plain text', 'application/x-new-type', 'hello.mytype')).toBeTruthy();
    });

    it('returns true for relevant filenames', () => {
      expect(
        isTextFile(
          'MAINTAINER Александр "alexander11354322283@me.com"',
          'application/octet-stream',
          'Dockerfile',
        ),
      ).toBeTruthy();
    });

    it('returns false for non-ASCII content for unknown types', () => {
      expect(isTextFile('{"éêė":"value"}', 'application/octet-stream', 'my.random')).toBeFalsy();
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

  describe('addFinalNewline', () => {
    it.each`
      input              | output
      ${'some text'}     | ${'some text\n'}
      ${'some text\n'}   | ${'some text\n'}
      ${'some text\n\n'} | ${'some text\n\n'}
      ${'some\n text'}   | ${'some\n text\n'}
    `('adds a newline if it doesnt already exist for input: $input', ({ input, output }) => {
      expect(insertFinalNewline(input)).toBe(output);
    });

    it.each`
      input                  | output
      ${'some text'}         | ${'some text\r\n'}
      ${'some text\r\n'}     | ${'some text\r\n'}
      ${'some text\n'}       | ${'some text\n\r\n'}
      ${'some text\r\n\r\n'} | ${'some text\r\n\r\n'}
      ${'some\r\n text'}     | ${'some\r\n text\r\n'}
    `('works with CRLF newline style; input: $input', ({ input, output }) => {
      expect(insertFinalNewline(input, '\r\n')).toBe(output);
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

      return readFileAsDataURL(file).then(contents => {
        expect(contents).toBe('data:image/png;base64,Zm9v');
      });
    });
  });
});
