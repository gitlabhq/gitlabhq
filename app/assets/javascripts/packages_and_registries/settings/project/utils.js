import { n__ } from '~/locale';
import { KEEP_N_OPTIONS, CADENCE_OPTIONS, OLDER_THAN_OPTIONS } from './constants';

export const findDefaultOption = (options) => {
  const item = options.find((o) => o.default);
  return item ? item.key : null;
};

export const olderThanTranslationGenerator = (variable) => n__('%d day', '%d days', variable);

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
  };
};
