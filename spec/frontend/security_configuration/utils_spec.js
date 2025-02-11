import { augmentFeatures, translateScannerNames } from '~/security_configuration/utils';
import { SCANNER_NAMES_MAP } from '~/security_configuration/constants';

describe('augmentFeatures', () => {
  const mockSecurityFeatures = [
    {
      name: 'SAST',
      type: 'SAST',
      security_features: {
        type: 'SAST',
      },
    },
  ];

  const expectedMockSecurityFeatures = [
    {
      name: 'SAST',
      type: 'SAST',
      securityFeatures: {
        type: 'SAST',
      },
    },
  ];

  const expectedInvalidMockSecurityFeatures = [
    {
      foo: 'bar',
      name: 'SAST',
      type: 'SAST',
      securityFeatures: {
        type: 'SAST',
      },
    },
  ];

  const expectedSecondarymockSecurityFeatures = [
    {
      name: 'DAST',
      type: 'DAST',
      helpPath: '/help/user/application_security/dast/_index',
      secondary: {
        type: 'DAST PROFILES',
        name: 'DAST PROFILES',
      },
      securityFeatures: {
        type: 'DAST',
        helpPath: '/help/user/application_security/dast/_index',
      },
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
      security_features: {
        type: 'DAST',
        help_path: '/help/user/application_security/dast/_index',
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
      customField: 'customvalue',
      securityFeatures: {
        type: 'SAST',
      },
    },
  ];

  const mockSecurityFeaturesDast = [
    {
      name: 'DAST',
      type: 'dast',
      security_features: {
        type: 'DAST',
      },
    },
  ];

  const mockValidCustomFeatureWithOnDemandAvailableFalse = [
    {
      name: 'DAST',
      type: 'dast',
      customField: 'customvalue',
      onDemandAvailable: false,
      badge: {},
      security_features: {
        type: 'dast',
      },
    },
  ];

  const mockValidCustomFeatureWithOnDemandAvailableTrue = [
    {
      name: 'DAST',
      type: 'dast',
      customField: 'customvalue',
      onDemandAvailable: true,
      badge: {},
      security_features: {
        type: 'dast',
      },
    },
  ];

  const mockValidCustomFeatureSnakeCase = [
    {
      name: 'SAST',
      type: 'SAST',
      custom_field: 'customvalue',
    },
  ];

  const expectedOutputDefault = {
    augmentedSecurityFeatures: expectedMockSecurityFeatures,
  };

  const expectedInvalidOutputDefault = {
    augmentedSecurityFeatures: expectedInvalidMockSecurityFeatures,
  };

  const expectedOutputSecondary = {
    augmentedSecurityFeatures: expectedSecondarymockSecurityFeatures,
  };

  const expectedOutputCustomFeature = {
    augmentedSecurityFeatures: mockValidCustomFeature,
  };

  const expectedOutputCustomFeatureWithOnDemandAvailableFalse = {
    augmentedSecurityFeatures: [
      {
        name: 'DAST',
        type: 'dast',
        customField: 'customvalue',
        onDemandAvailable: false,
        securityFeatures: {
          type: 'dast',
        },
      },
    ],
  };

  const expectedOutputCustomFeatureWithOnDemandAvailableTrue = {
    augmentedSecurityFeatures: [
      {
        name: 'DAST',
        type: 'dast',
        customField: 'customvalue',
        onDemandAvailable: true,
        badge: {},
        securityFeatures: {
          type: 'dast',
        },
      },
    ],
  };

  describe('returns an object with augmentedSecurityFeatures  when', () => {
    it('given an properly formatted array', () => {
      expect(augmentFeatures(mockSecurityFeatures)).toEqual(expectedOutputDefault);
    });

    it('given an invalid populated array', () => {
      expect(
        augmentFeatures([{ ...mockSecurityFeatures[0], ...mockInvalidCustomFeature[0] }]),
      ).toEqual(expectedInvalidOutputDefault);
    });

    it('features have secondary key', () => {
      expect(
        augmentFeatures([{ ...mockSecurityFeatures[0], ...mockFeaturesWithSecondary[0] }]),
      ).toEqual(expectedOutputSecondary);
    });

    it('given a valid populated array', () => {
      expect(
        augmentFeatures([{ ...mockSecurityFeatures[0], ...mockValidCustomFeature[0] }]),
      ).toEqual(expectedOutputCustomFeature);
    });
  });

  describe('returns an object with camelcased keys', () => {
    it('given a customfeature in snakecase', () => {
      expect(
        augmentFeatures([{ ...mockSecurityFeatures[0], ...mockValidCustomFeatureSnakeCase[0] }]),
      ).toEqual(expectedOutputCustomFeature);
    });
  });

  describe('follows onDemandAvailable', () => {
    it('deletes badge when false', () => {
      expect(
        augmentFeatures([
          {
            ...mockSecurityFeaturesDast[0],
            ...mockValidCustomFeatureWithOnDemandAvailableFalse[0],
          },
        ]),
      ).toEqual(expectedOutputCustomFeatureWithOnDemandAvailableFalse);
    });

    it('keeps badge when true', () => {
      expect(
        augmentFeatures([
          { ...mockSecurityFeaturesDast[0], ...mockValidCustomFeatureWithOnDemandAvailableTrue[0] },
        ]),
      ).toEqual(expectedOutputCustomFeatureWithOnDemandAvailableTrue);
    });
  });
});

describe('translateScannerNames', () => {
  it.each(['', undefined, null, 1, 'UNKNOWN_SCANNER_KEY'])('returns %p as is', (key) => {
    expect(translateScannerNames([key])).toEqual([key]);
  });

  it('returns an empty array if no input is provided', () => {
    expect(translateScannerNames([])).toEqual([]);
  });

  it('returns translated scanner names', () => {
    expect(translateScannerNames(Object.keys(SCANNER_NAMES_MAP))).toEqual(
      Object.values(SCANNER_NAMES_MAP),
    );
  });
});
