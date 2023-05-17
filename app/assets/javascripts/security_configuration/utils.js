import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { SCANNER_NAMES_MAP } from '~/security_configuration/components/constants';

/**
 * This function takes in 3 arrays of objects, securityFeatures and features.
 * securityFeatures are static arrays living in the constants.
 * features is dynamic and coming from the backend.
 * This function builds a superset of those arrays.
 * It looks for matching keys within the dynamic and the static arrays
 * and will enrich the objects with the available static data.
 * @param [{}] securityFeatures
 * @param [{}] features
 * @returns {Object} Object with enriched features from constants divided into Security and Compliance Features
 */

export const augmentFeatures = (securityFeatures, features = []) => {
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

    if (augmented.badge && augmented.metaInfoPath) {
      augmented.badge.badgeHref = augmented.metaInfoPath;
    }

    return augmented;
  };

  return {
    augmentedSecurityFeatures: securityFeatures.map((feature) => augmentFeature(feature)),
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
