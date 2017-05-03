import {
  __,
  n__,
} from '../locale';

export default (Vue) => {
  Vue.mixin({
    methods: {
      __(text) { return __(text); },
      n__(text, pluralText, count) {
        const translated = n__(text, pluralText, count).replace(/%d/g, count).split('|');
        return translated[translated.length - 1];
      },
      s__(keyOrContext, key) {
        const normalizedKey = key ? `${keyOrContext}|${key}` : keyOrContext;
        // eslint-disable-next-line no-underscore-dangle
        const translated = this.__(normalizedKey).split('|');

        return translated[translated.length - 1];
      },
    },
  });
};
