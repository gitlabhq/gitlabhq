import { augmentFeatures, translateScannerNames } from '~/security_configuration/utils';
import { SCANNER_NAMES_MAP } from '~/security_configuration/components/constants';

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
