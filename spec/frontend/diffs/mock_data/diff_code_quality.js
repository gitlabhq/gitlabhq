export const multipleFindingsArr = [
  {
    severity: 'minor',
    description: 'mocked minor Issue',
    line: 2,
  },
  {
    severity: 'major',
    description: 'mocked major Issue',
    line: 3,
  },
  {
    severity: 'info',
    description: 'mocked info Issue',
    line: 3,
  },
  {
    severity: 'critical',
    description: 'mocked critical Issue',
    line: 3,
  },
  {
    severity: 'blocker',
    description: 'mocked blocker Issue',
    line: 3,
  },
  {
    severity: 'unknown',
    description: 'mocked unknown Issue',
    line: 3,
  },
];

export const fiveFindings = {
  filePath: 'index.js',
  codequality: multipleFindingsArr.slice(0, 5),
};

export const threeFindings = {
  filePath: 'index.js',
  codequality: multipleFindingsArr.slice(0, 3),
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
        lineDrafts: [],
      },
    },
    {
      left: {
        type: null,
        old_line: 2,
        new_line: 1,
        codequality: [],
        lineDrafts: [],
      },
    },
    {
      left: {
        type: 'new',
        old_line: null,
        new_line: 2,

        codequality: [multipleFindingsArr[0]],
        lineDrafts: [],
      },
    },
  ],
};
