import Vue from 'vue';
import { isEE } from '~/lib/utils/common_utils';

Vue.mixin({
  computed: {
    isEE() {
      return isEE();
    },
  },
});
