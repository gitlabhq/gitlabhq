import { augmentFeatures } from '~/security_configuration/utils';

const mockSecurityFeatures = [
  {
    name: 'SAST',
    type: 'SAST',
  },
];

const mockComplianceFeatures = [
  {
    name: 'LICENSE_COMPLIANCE',
    type: 'LICENSE_COMPLIANCE',
  },
];

const mockFeaturesWithSecondary = [
  {
    name: 'DAST',
    type: 'DAST',
    secondary: {
      type: 'DAST PROFILES',
      name: 'DAST PROFILES',
    },
  },
];

const mockInvalidCustomFeature = [
  {
    foo: 'bar',
  },
];

const mockValidCustomFeature = [
  {
    name: 'SAST',
    type: 'SAST',
    customfield: 'customvalue',
  },
];

const expectedOutputDefault = {
  augmentedSecurityFeatures: mockSecurityFeatures,
  augmentedComplianceFeatures: mockComplianceFeatures,
};

const expectedOutputSecondary = {
  augmentedSecurityFeatures: mockSecurityFeatures,
  augmentedComplianceFeatures: mockFeaturesWithSecondary,
};

const expectedOutputCustomFeature = {
  augmentedSecurityFeatures: mockValidCustomFeature,
  augmentedComplianceFeatures: mockComplianceFeatures,
};

describe('returns an object with augmentedSecurityFeatures and augmentedComplianceFeatures when', () => {
  it('given an empty array', () => {
    expect(augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, [])).toEqual(
      expectedOutputDefault,
    );
  });

  it('given an invalid populated array', () => {
    expect(
      augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, mockInvalidCustomFeature),
    ).toEqual(expectedOutputDefault);
  });

  it('features have secondary key', () => {
    expect(augmentFeatures(mockSecurityFeatures, mockFeaturesWithSecondary, [])).toEqual(
      expectedOutputSecondary,
    );
  });

  it('given a valid populated array', () => {
    expect(
      augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, mockValidCustomFeature),
    ).toEqual(expectedOutputCustomFeature);
  });
});
