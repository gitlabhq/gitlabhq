import languageLoader from '~/content_editor/services/highlight_js_language_loader';
// Language map from Rouge::Lexer to highlight.js
// Rouge::Lexer - We use it on the BE to determine the language of a source file (https://github.com/rouge-ruby/rouge/blob/master/docs/Languages.md).
// Highlight.js - We use it on the FE to highlight the syntax of a source file (https://github.com/highlightjs/highlight.js/tree/main/src/languages).
export const ROUGE_TO_HLJS_LANGUAGE_MAP = {
  ...Object.fromEntries(Object.keys(languageLoader).map((lang) => [lang, lang])),
  // Override with special mappings
  bsl: '1c',
  pascal: 'delphi',
  jinja: 'django',
  docker: 'dockerfile',
  batchfile: 'dos',
  elixir: 'elixir',
  html: 'xml',
  hylang: 'hy',
  tex: 'latex',
  common_lisp: 'lisp',
  hlsl: 'lsl',
  make: 'makefile',
  objective_c: 'objectivec',
  python3: 'python',
  shell: 'sh',
  vb: 'vbnet',
  viml: 'vim',
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

export const CODEOWNERS_FILE_NAME = 'CODEOWNERS';

export const CODEOWNERS_LANGUAGE = 'codeowners';

export const SVELTE_LANGUAGE = 'svelte';
