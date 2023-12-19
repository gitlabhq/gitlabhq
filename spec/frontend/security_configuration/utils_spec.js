import { augmentFeatures, translateScannerNames } from '~/security_configuration/utils';
import { SCANNER_NAMES_MAP } from '~/security_configuration/constants';

describe('augmentFeatures', () => {
  const mockSecurityFeatures = [
    {
      name: 'SAST',
      type: 'SAST',
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
      customField: 'customvalue',
    },
  ];

  const mockSecurityFeaturesDast = [
    {
      name: 'DAST',
      type: 'dast',
    },
  ];

  const mockValidCustomFeatureWithOnDemandAvailableFalse = [
    {
      name: 'DAST',
      type: 'dast',
      customField: 'customvalue',
      onDemandAvailable: false,
      badge: {},
    },
  ];

  const mockValidCustomFeatureWithOnDemandAvailableTrue = [
    {
      name: 'DAST',
      type: 'dast',
      customField: 'customvalue',
      onDemandAvailable: true,
      badge: {},
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
    augmentedSecurityFeatures: mockSecurityFeatures,
  };

  const expectedOutputSecondary = {
    augmentedSecurityFeatures: mockSecurityFeatures,
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
      },
    ],
  };

  describe('returns an object with augmentedSecurityFeatures  when', () => {
    it('given an empty array', () => {
      expect(augmentFeatures(mockSecurityFeatures, [])).toEqual(expectedOutputDefault);
    });

    it('given an invalid populated array', () => {
      expect(augmentFeatures(mockSecurityFeatures, mockInvalidCustomFeature)).toEqual(
        expectedOutputDefault,
      );
    });

    it('features have secondary key', () => {
      expect(augmentFeatures(mockSecurityFeatures, mockFeaturesWithSecondary, [])).toEqual(
        expectedOutputSecondary,
      );
    });

    it('given a valid populated array', () => {
      expect(augmentFeatures(mockSecurityFeatures, mockValidCustomFeature)).toEqual(
        expectedOutputCustomFeature,
      );
    });
  });

  describe('returns an object with camelcased keys', () => {
    it('given a customfeature in snakecase', () => {
      expect(augmentFeatures(mockSecurityFeatures, mockValidCustomFeatureSnakeCase)).toEqual(
        expectedOutputCustomFeature,
      );
    });
  });

  describe('follows onDemandAvailable', () => {
    it('deletes badge when false', () => {
      expect(
        augmentFeatures(mockSecurityFeaturesDast, mockValidCustomFeatureWithOnDemandAvailableFalse),
      ).toEqual(expectedOutputCustomFeatureWithOnDemandAvailableFalse);
    });

    it('keeps badge when true', () => {
      expect(
        augmentFeatures(mockSecurityFeaturesDast, mockValidCustomFeatureWithOnDemandAvailableTrue),
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
