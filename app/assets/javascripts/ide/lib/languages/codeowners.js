const conf = {
  comments: {
    lineComment: '#',
  },
  autoClosingPairs: [{ open: '[', close: ']' }],
  surroundingPairs: [{ open: '[', close: ']' }],
};

const language = {
  tokenizer: {
    root: [
      // comment
      [/^#.*$/, 'comment'],

      // optional approval
      [/^\^/, 'constant.numeric'],

      // number of approvers
      [/\[\d+\]$/, 'constant.numeric'],

      // section
      [/\[(?!\d+\])[^\]]+\]/, 'namespace'],

      // pattern
      [/^\s*(\S+)/, 'regexp'],

      // owner
      [/\S*@.*$/, 'variable.value'],
    ],
  },
};

export default {
  id: 'codeowners',
  extensions: ['codeowners'],
  aliases: ['CODEOWNERS'],
  conf,
  language,
};
