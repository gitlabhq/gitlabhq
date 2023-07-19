import { getSeverity } from '~/ci/reports/utils';

import {
  findingSastInfo,
  findingSastInfoEnhanced,
  findingCodeQualityInfo,
  findingCodeQualityInfoEnhanced,
  findingUnknownInfo,
  findingUnknownInfoEnhanced,
  findingsArray,
  findingsArrayEnhanced,
} from './mock_data/mock_data';

describe('getSeverity utility function', () => {
  it('should enhance finding with sast scale', () => {
    expect(getSeverity(findingSastInfo)).toEqual(findingSastInfoEnhanced);
  });

  it('should enhance finding with codequality scale', () => {
    expect(getSeverity(findingCodeQualityInfo)).toEqual(findingCodeQualityInfoEnhanced);
  });

  it('should use codeQuality scale when scale is unknown', () => {
    expect(getSeverity(findingUnknownInfo)).toEqual(findingUnknownInfoEnhanced);
  });

  it('should correctly enhance an array of findings', () => {
    expect(getSeverity(findingsArray)).toEqual(findingsArrayEnhanced);
  });
});
