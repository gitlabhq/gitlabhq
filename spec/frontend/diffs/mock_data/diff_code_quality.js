export const multipleFindingsArrCodeQualityScale = [
  {
    severity: 'minor',
    description: 'mocked minor Issue',
    line: 2,
    scale: 'codeQuality',
  },
  {
    severity: 'major',
    description: 'mocked major Issue',
    line: 3,
    scale: 'codeQuality',
  },
  {
    severity: 'info',
    description: 'mocked info Issue',
    line: 3,
    scale: 'codeQuality',
  },
  {
    severity: 'critical',
    description: 'mocked critical Issue',
    line: 3,
    scale: 'codeQuality',
  },
  {
    severity: 'blocker',
    description: 'mocked blocker Issue',
    line: 3,
    scale: 'codeQuality',
  },
  {
    severity: 'unknown',
    description: 'mocked unknown Issue',
    line: 3,
    scale: 'codeQuality',
  },
];

export const multipleFindingsArrSastScale = [
  {
    severity: 'low',
    description: 'mocked low Issue',
    line: 2,
    scale: 'sast',
  },
  {
    severity: 'medium',
    description: 'mocked medium Issue',
    line: 3,
    scale: 'sast',
  },
  {
    severity: 'info',
    description: 'mocked info Issue',
    line: 3,
    scale: 'sast',
  },
  {
    severity: 'high',
    description: 'mocked high Issue',
    line: 3,
    scale: 'sast',
  },
  {
    severity: 'critical',
    description: 'mocked critical Issue',
    line: 3,
    scale: 'sast',
  },
  {
    severity: 'unknown',
    description: 'mocked unknown Issue',
    line: 3,
    scale: 'sast',
  },
];

export const multipleCodeQualityNoSast = {
  codeQuality: multipleFindingsArrCodeQualityScale,
  sast: [],
};

export const multipleSastNoCodeQuality = {
  codeQuality: [],
  sast: multipleFindingsArrSastScale,
};

export const fiveCodeQualityFindings = {
  filePath: 'index.js',
  codequality: multipleFindingsArrCodeQualityScale.slice(0, 5),
};

export const threeCodeQualityFindings = {
  filePath: 'index.js',
  codequality: multipleFindingsArrCodeQualityScale.slice(0, 3),
};

export const singularCodeQualityFinding = {
  filePath: 'index.js',
  codequality: [multipleFindingsArrCodeQualityScale[0]],
};

export const singularFindingSast = {
  filePath: 'index.js',
  sast: [multipleFindingsArrSastScale[0]],
};

export const threeSastFindings = {
  filePath: 'index.js',
  sast: multipleFindingsArrSastScale.slice(0, 3),
};

export const oneCodeQualityTwoSastFindings = {
  filePath: 'index.js',
  sast: multipleFindingsArrSastScale.slice(0, 2),
  codequality: [multipleFindingsArrCodeQualityScale[0]],
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

        codequality: [multipleFindingsArrCodeQualityScale[0]],
        lineDrafts: [],
      },
    },
  ],
};
