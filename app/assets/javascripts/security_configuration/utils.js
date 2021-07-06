import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

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
