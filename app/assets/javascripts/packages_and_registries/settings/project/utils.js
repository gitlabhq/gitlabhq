import { n__ } from '~/locale';
import {
  KEEP_N_OPTIONS,
  CADENCE_OPTIONS,
  OLDER_THAN_OPTIONS,
  KEEP_N_DUPLICATED_PACKAGE_FILES_FIELDNAME,
  KEEP_N_DUPLICATED_PACKAGE_FILES_OPTIONS,
  MinimumAccessLevelText,
} from './constants';

export const findDefaultOption = (options) => {
  const item = options.find((o) => o.default);
  return item ? item.key : null;
};

const DAYS_PER_YEAR = 365;

export const olderThanTranslationGenerator = (variable) => {
  if (variable >= DAYS_PER_YEAR && variable % DAYS_PER_YEAR === 0) {
    const years = variable / DAYS_PER_YEAR;
    return n__('%d year', '%d years', years);
  }
  return n__('%d day', '%d days', variable);
};

export const keepNTranslationGenerator = (variable) =>
  n__('%d tag per image name', '%d tags per image name', variable);

export const optionLabelGenerator = (collection, translationFn) => {
  const result = collection.map((option) => ({
    ...option,
    label: translationFn(option.variable),
  }));
  result.unshift({ key: null, label: '' });
  return result;
};

export const formOptionsGenerator = () => {
  return {
    olderThan: optionLabelGenerator(OLDER_THAN_OPTIONS, olderThanTranslationGenerator),
    cadence: CADENCE_OPTIONS,
    keepN: optionLabelGenerator(KEEP_N_OPTIONS, keepNTranslationGenerator),
    [KEEP_N_DUPLICATED_PACKAGE_FILES_FIELDNAME]: KEEP_N_DUPLICATED_PACKAGE_FILES_OPTIONS,
  };
};

export const getAccessLevelLabel = (level) => {
  return MinimumAccessLevelText[level];
};
