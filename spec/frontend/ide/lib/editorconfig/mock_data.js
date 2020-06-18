export const exampleConfigs = [
  {
    path: 'foo/bar/baz/.editorconfig',
    content: `
[*]
tab_width = 6
indent_style = tab
`,
  },
  {
    path: 'foo/bar/.editorconfig',
    content: `
root = false

[*]
indent_size = 5
indent_style = space
trim_trailing_whitespace = true

[*_spec.{js,py}]
end_of_line = crlf
    `,
  },
  {
    path: 'foo/.editorconfig',
    content: `
[*]
tab_width = 4
indent_style = tab
    `,
  },
  {
    path: '.editorconfig',
    content: `
root = true

[*]
indent_size = 3
indent_style = space
end_of_line = lf
insert_final_newline = true

[*.js]
indent_size = 2
indent_style = space
trim_trailing_whitespace = true

[*.txt]
end_of_line = crlf
    `,
  },
  {
    path: 'foo/bar/root/.editorconfig',
    content: `
root = true

[*]
tab_width = 1
indent_style = tab
    `,
  },
];

export const exampleFiles = [
  {
    path: 'foo/bar/root/README.md',
    rules: {
      indent_style: 'tab', // foo/bar/root/.editorconfig
      tab_width: '1', // foo/bar/root/.editorconfig
    },
    monacoRules: {
      insertSpaces: false,
      tabSize: 1,
    },
  },
  {
    path: 'foo/bar/baz/my_spec.js',
    rules: {
      end_of_line: 'crlf', // foo/bar/.editorconfig (for _spec.js files)
      indent_size: '5', // foo/bar/.editorconfig
      indent_style: 'tab', // foo/bar/baz/.editorconfig
      insert_final_newline: 'true', // .editorconfig
      tab_width: '6', // foo/bar/baz/.editorconfig
      trim_trailing_whitespace: 'true', // .editorconfig (for .js files)
    },
    monacoRules: {
      endOfLine: 1,
      insertFinalNewline: true,
      insertSpaces: false,
      tabSize: 6,
      trimTrailingWhitespace: true,
    },
  },
  {
    path: 'foo/my_file.js',
    rules: {
      end_of_line: 'lf', // .editorconfig
      indent_size: '2', // .editorconfig (for .js files)
      indent_style: 'tab', // foo/.editorconfig
      insert_final_newline: 'true', // .editorconfig
      tab_width: '4', // foo/.editorconfig
      trim_trailing_whitespace: 'true', // .editorconfig (for .js files)
    },
    monacoRules: {
      endOfLine: 0,
      insertFinalNewline: true,
      insertSpaces: false,
      tabSize: 4,
      trimTrailingWhitespace: true,
    },
  },
  {
    path: 'foo/my_file.md',
    rules: {
      end_of_line: 'lf', // .editorconfig
      indent_size: '3', // .editorconfig
      indent_style: 'tab', // foo/.editorconfig
      insert_final_newline: 'true', // .editorconfig
      tab_width: '4', // foo/.editorconfig
    },
    monacoRules: {
      endOfLine: 0,
      insertFinalNewline: true,
      insertSpaces: false,
      tabSize: 4,
    },
  },
  {
    path: 'foo/bar/my_file.txt',
    rules: {
      end_of_line: 'crlf', // .editorconfig (for .txt files)
      indent_size: '5', // foo/bar/.editorconfig
      indent_style: 'space', // foo/bar/.editorconfig
      insert_final_newline: 'true', // .editorconfig
      tab_width: '4', // foo/.editorconfig
      trim_trailing_whitespace: 'true', // foo/bar/.editorconfig
    },
    monacoRules: {
      endOfLine: 1,
      insertFinalNewline: true,
      insertSpaces: true,
      tabSize: 4,
      trimTrailingWhitespace: true,
    },
  },
];
