import { isEmpty } from 'lodash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { SCANNER_NAMES_MAP } from '~/security_configuration/constants';
import { REPORT_TYPE_DAST } from '~/vue_shared/security_reports/constants';

/**
 * This function takes in a arrays of features.
 * features is dynamic and coming from the backend.
 * securityFeatures is nested in features and are static arrays living in backend constants
 * This function takes the nested securityFeatures config and flattens it to the top level object.
 * It then filters out any scanner features that lack a security config for rednering in the UI
 * @param [{}] features
 * @param {Object} securityFeatures Object containing client side UI options
 * @returns {Object} Object with enriched features from constants divided into Security and compliance Features
 */

export const augmentFeatures = (features = []) => {
  const featuresByType = features.reduce((acc, feature) => {
    acc[feature.type] = convertObjectPropsToCamelCase(feature, { deep: true });
    return acc;
  }, {});

  /**
   * Track feature configs that are used as nested elements in the UI
   * so they aren't rendered at the top level as a seperate card
   */
  const secondaryFeatures = [];

  // Modify each feature
  const augmentFeature = (feature) => {
    const augmented = {
      ...feature,
      ...featuresByType[feature.type],
    };

    // Secondary layer copies some values from the first layer
    if (augmented.secondary) {
      augmented.secondary = { ...augmented.secondary, ...featuresByType[feature.secondary.type] };
      secondaryFeatures.push(feature.secondary.type);
    }

    if (augmented.type === REPORT_TYPE_DAST && !augmented.onDemandAvailable) {
      delete augmented.badge;
    }

    if (augmented.badge && augmented.metaInfoPath) {
      augmented.badge.badgeHref = augmented.metaInfoPath;
    }

    return augmented;
  };

  // Filter out any features that lack a security feature definition or is used as a nested UI element
  const filterFeatures = (feature) => {
    return !secondaryFeatures.includes(feature.type) && !isEmpty(feature.securityFeatures || {});
  };

  // Convert backend provided properties to camelCase, and spread nested security config to the root
  // level for UI rendering.
  const flattenFeatures = (feature) => {
    const flattenedFeature = convertObjectPropsToCamelCase(feature, { deep: true });
    return augmentFeature({ ...flattenedFeature, ...flattenedFeature.securityFeatures });
  };

  return {
    augmentedSecurityFeatures: features.map(flattenFeatures).filter(filterFeatures),
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
