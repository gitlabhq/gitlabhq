export const multipleFindingsArr = [
  {
    severity: 'minor',
    description: 'Unexpected Debugger Statement.',
    line: 2,
  },
  {
    severity: 'major',
    description:
      'Function `aVeryLongFunction` has 52 lines of code (exceeds 25 allowed). Consider refactoring.',
    line: 3,
  },
  {
    severity: 'minor',
    description: 'Arrow function has too many statements (52). Maximum allowed is 30.',
    line: 3,
  },
];

export const multipleFindings = {
  filePath: 'index.js',
  codequality: multipleFindingsArr,
};

export const singularFinding = {
  filePath: 'index.js',
  codequality: [multipleFindingsArr[0]],
};

export const diffCodeQuality = {
  diffFile: { file_hash: '123' },
  diffLines: [
    {
      left: {
        type: 'old',
        old_line: 1,
        new_line: null,
        codequality: [],
        lineDraft: {},
      },
    },
    {
      left: {
        type: null,
        old_line: 2,
        new_line: 1,
        codequality: [],
        lineDraft: {},
      },
    },
    {
      left: {
        type: 'new',
        old_line: null,
        new_line: 2,

        codequality: [multipleFindingsArr[0]],
        lineDraft: {},
      },
    },
  ],
};
