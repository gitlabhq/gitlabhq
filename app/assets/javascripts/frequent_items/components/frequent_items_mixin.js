import { TRANSLATION_KEYS } from '../constants';

export default {
  props: {
    namespace: {
      type: String,
      required: true,
    },
  },
  methods: {
    getTranslations(keys) {
      const translationStrings = keys.reduce(
        (acc, key) => ({
          ...acc,
          [key]: TRANSLATION_KEYS[this.namespace][key],
        }),
        {},
      );

      return translationStrings;
    },
  },
};
