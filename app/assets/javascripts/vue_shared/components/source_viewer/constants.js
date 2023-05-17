// Language map from Rouge::Lexer to highlight.js
// Rouge::Lexer - We use it on the BE to determine the language of a source file (https://github.com/rouge-ruby/rouge/blob/master/docs/Languages.md).
// Highlight.js - We use it on the FE to highlight the syntax of a source file (https://github.com/highlightjs/highlight.js/tree/main/src/languages).
export const ROUGE_TO_HLJS_LANGUAGE_MAP = {
  bsl: '1c',
  actionscript: 'actionscript',
  ada: 'ada',
  apache: 'apache',
  applescript: 'applescript',
  armasm: 'armasm',
  awk: 'awk',
  c: 'c',
  ceylon: 'ceylon',
  clean: 'clean',
  clojure: 'clojure',
  cmake: 'cmake',
  coffeescript: 'coffeescript',
  coq: 'coq',
  cpp: 'cpp',
  crystal: 'crystal',
  csharp: 'csharp',
  css: 'css',
  d: 'd',
  dart: 'dart',
  pascal: 'delphi',
  diff: 'diff',
  jinja: 'django',
  docker: 'dockerfile',
  batchfile: 'dos',
  elixir: 'elixir',
  elm: 'elm',
  erb: 'erb',
  erlang: 'erlang',
  fortran: 'fortran',
  fsharp: 'fsharp',
  gherkin: 'gherkin',
  glsl: 'glsl',
  go: 'go',
  gradle: 'gradle',
  groovy: 'groovy',
  haml: 'haml',
  handlebars: 'handlebars',
  haskell: 'haskell',
  haxe: 'haxe',
  http: 'http',
  html: 'xml',
  hylang: 'hy',
  ini: 'ini',
  isbl: 'isbl',
  java: 'java',
  javascript: 'javascript',
  json: 'json',
  julia: 'julia',
  kotlin: 'kotlin',
  lasso: 'lasso',
  tex: 'latex',
  common_lisp: 'lisp',
  livescript: 'livescript',
  llvm: 'llvm',
  hlsl: 'lsl',
  lua: 'lua',
  make: 'makefile',
  markdown: 'markdown',
  mathematica: 'mathematica',
  matlab: 'matlab',
  moonscript: 'moonscript',
  nginx: 'nginx',
  nim: 'nim',
  nix: 'nix',
  objective_c: 'objectivec',
  ocaml: 'ocaml',
  perl: 'perl',
  php: 'php',
  plaintext: 'plaintext',
  pony: 'pony',
  powershell: 'powershell',
  prolog: 'prolog',
  properties: 'properties',
  protobuf: 'protobuf',
  puppet: 'puppet',
  python: 'python',
  python3: 'python',
  q: 'q',
  qml: 'qml',
  r: 'r',
  reasonml: 'reasonml',
  ruby: 'ruby',
  rust: 'rust',
  sas: 'sas',
  scala: 'scala',
  scheme: 'scheme',
  scss: 'scss',
  shell: 'sh',
  smalltalk: 'smalltalk',
  sml: 'sml',
  sqf: 'sqf',
  sql: 'sql',
  stan: 'stan',
  stata: 'stata',
  swift: 'swift',
  tap: 'tap',
  tcl: 'tcl',
  twig: 'twig',
  typescript: 'typescript',
  vala: 'vala',
  vb: 'vbnet',
  verilog: 'verilog',
  vhdl: 'vhdl',
  viml: 'vim',
  xml: 'xml',
  xquery: 'xquery',
  yaml: 'yaml',
};

export const EVENT_ACTION = 'view_source';

export const EVENT_LABEL_VIEWER = 'source_viewer';

export const EVENT_LABEL_FALLBACK = 'legacy_fallback';

export const LINES_PER_CHUNK = 70;

export const NEWLINE = '\n';

export const BIDI_CHARS = [
  '\u202A', // Left-to-Right Embedding (Try treating following text as left-to-right)
  '\u202B', // Right-to-Left Embedding (Try treating following text as right-to-left)
  '\u202D', // Left-to-Right Override (Force treating following text as left-to-right)
  '\u202E', // Right-to-Left Override (Force treating following text as right-to-left)
  '\u2066', // Left-to-Right Isolate (Force treating following text as left-to-right without affecting adjacent text)
  '\u2067', // Right-to-Left Isolate (Force treating following text as right-to-left without affecting adjacent text)
  '\u2068', // First Strong Isolate (Force treating following text in direction indicated by the next character)
  '\u202C', // Pop Directional Formatting (Terminate nearest LRE, RLE, LRO, or RLO)
  '\u2069', // Pop Directional Isolate (Terminate nearest LRI or RLI)
  '\u061C', // Arabic Letter Mark (Right-to-left zero-width Arabic character)
  '\u200F', // Right-to-Left Mark (Right-to-left zero-width character non-Arabic character)
  '\u200E', // Left-to-Right Mark (Left-to-right zero-width character)
];

export const BIDI_CHARS_CLASS_LIST = 'unicode-bidi has-tooltip';

export const BIDI_CHAR_TOOLTIP = 'Potentially unwanted character detected: Unicode BiDi Control';

/**
 * We fallback to highlighting these languages with Rouge, see the following issues for more detail:
 * Python: https://gitlab.com/gitlab-org/gitlab/-/issues/384375#note_1212752013
 * HAML: https://github.com/highlightjs/highlight.js/issues/3783
 * */
export const LEGACY_FALLBACKS = ['python', 'haml'];
