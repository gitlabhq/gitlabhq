import { n__ } from '~/locale';
import { KEEP_N_OPTIONS, CADENCE_OPTIONS, OLDER_THAN_OPTIONS } from './constants';

export const findDefaultOption = options => {
  const item = options.find(o => o.default);
  return item ? item.key : null;
};

export const mapComputedToEvent = (list, root) => {
  const result = {};
  list.forEach(e => {
    result[e] = {
      get() {
        return this[root][e];
      },
      set(value) {
        this.$emit('input', { newValue: { ...this[root], [e]: value }, modified: e });
      },
    };
  });
  return result;
};

export const olderThanTranslationGenerator = variable =>
  n__(
    '%d day until tags are automatically removed',
    '%d days until tags are automatically removed',
    variable,
  );

export const keepNTranslationGenerator = variable =>
  n__('%d tag per image name', '%d tags per image name', variable);

export const optionLabelGenerator = (collection, translationFn) =>
  collection.map(option => ({
    ...option,
    label: translationFn(option.variable),
  }));

export const formOptionsGenerator = () => {
  return {
    olderThan: optionLabelGenerator(OLDER_THAN_OPTIONS, olderThanTranslationGenerator),
    cadence: CADENCE_OPTIONS,
    keepN: optionLabelGenerator(KEEP_N_OPTIONS, keepNTranslationGenerator),
  };
};
