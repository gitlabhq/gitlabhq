import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { SCANNER_NAMES_MAP } from '~/security_configuration/components/constants';

export const augmentFeatures = (securityFeatures, complianceFeatures, features = []) => {
  const featuresByType = features.reduce((acc, feature) => {
    acc[feature.type] = convertObjectPropsToCamelCase(feature, { deep: true });
    return acc;
  }, {});

  const augmentFeature = (feature) => {
    const augmented = {
      ...feature,
      ...featuresByType[feature.type],
    };

    if (augmented.secondary) {
      augmented.secondary = { ...augmented.secondary, ...featuresByType[feature.secondary.type] };
    }

    return augmented;
  };

  return {
    augmentedSecurityFeatures: securityFeatures.map((feature) => augmentFeature(feature)),
    augmentedComplianceFeatures: complianceFeatures.map((feature) => augmentFeature(feature)),
  };
};

/**
 * Converts a list of security scanner IDs (such as SAST_IAC) into a list of their translated
 * names defined in the SCANNER_NAMES_MAP constant (eg. IaC Scanning).
 *
 * @param {String[]} scannerNames
 * @returns {String[]}
 */
export const translateScannerNames = (scannerNames = []) =>
  scannerNames.map((scannerName) => SCANNER_NAMES_MAP[scannerName] || scannerName);
