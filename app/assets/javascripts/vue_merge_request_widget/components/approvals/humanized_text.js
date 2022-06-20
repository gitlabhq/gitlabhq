import { __ } from '~/locale';

const humanizeRules = (invalidRules) => {
  if (invalidRules.length > 1) {
    return invalidRules.reduce((rules, { name }, index) => {
      if (index === invalidRules.length - 1) {
        return `${rules}${__(' and ')}"${name}"`;
      }
      return rules ? `${rules}, "${name}"` : `"${name}"`;
    }, '');
  }
  return `"${invalidRules[0].name}"`;
};

export const humanizeInvalidApproversRules = (invalidRules) => {
  const ruleCount = invalidRules.length;

  if (!ruleCount) {
    return '';
  }

  return humanizeRules(invalidRules);
};
