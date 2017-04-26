import {
  __,
  n__,
  s__,
} from '../locale';

export default (Vue) => {
  Vue.mixin({
    methods: {
      __(text) { return __(text); },
      n__(text, pluralText, count) {
        return n__(text, pluralText, count).replace(/%d/g, count);
      },
      s__(context, key) { return s__(context, key); },
    },
  });
};
