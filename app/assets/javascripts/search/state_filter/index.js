import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import StateFilter from './components/state_filter.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-search-filter-by-state');

  if (!el) return false;

  return new Vue({
    el,
    components: {
      StateFilter,
    },
    data() {
      const { dataset } = this.$options.el;
      return {
        scope: dataset.scope,
        state: dataset.state,
      };
    },

    render(createElement) {
      return createElement('state-filter', {
        props: {
          scope: this.scope,
          state: this.state,
        },
      });
    },
  });
};
