const multipleFindingsArrCodeQualityScale = [
  {
    severity: 'minor',
    description: 'mocked minor Issue',
    line: 2,
    scale: 'codeQuality',
    text: 'mocked minor Issue',
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

const multipleFindingsArrSastScale = [
  {
    severity: 'low',
    description: 'mocked low Issue',
    line: 2,
    scale: 'sast',
    text: 'mocked low Issue',
    state: 'detected',
  },
  {
    severity: 'medium',
    description: 'mocked medium Issue',
    line: 3,
    scale: 'sast',
    text: 'mocked medium Issue',
    state: 'dismissed',
  },
  {
    severity: 'info',
    description: 'mocked info Issue',
    line: 3,
    scale: 'sast',
    state: 'detected',
  },
  {
    severity: 'high',
    description: 'mocked high Issue',
    line: 3,
    scale: 'sast',
    state: 'dismissed',
  },
  {
    severity: 'critical',
    description: 'mocked critical Issue',
    line: 3,
    scale: 'sast',
    state: 'detected',
  },
  {
    severity: 'unknown',
    description: 'mocked unknown Issue',
    line: 3,
    scale: 'sast',
    state: 'dismissed',
  },
];

export const singularCodeQualityFinding = [multipleFindingsArrCodeQualityScale[0]];
export const singularSastFinding = [multipleFindingsArrSastScale[0]];
export const singularSastFindingDetected = [multipleFindingsArrSastScale[0]];
export const singularSastFindingDismissed = [multipleFindingsArrSastScale[1]];

export const fiveCodeQualityFindings = multipleFindingsArrCodeQualityScale.slice(0, 5);
export const filePath = 'testPath';
export const scale = 'exampleScale';

export const dropdownIcon = {
  id: 'noise.rb-2',
  key: 'mockedkey',
  name: 'severity-medium',
  class: 'gl-text-orange-400',
};
