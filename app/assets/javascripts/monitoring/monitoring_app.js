import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import createRouter from './router';
import { createStore } from './stores';
import { stateAndPropsFromDataset } from './utils';

Vue.use(GlToast);

export default (props = {}) => {
  const el = document.getElementById('prometheus-graphs');

  if (el && el.dataset) {
    const { metricsDashboardBasePath, ...dataset } = el.dataset;

    const {
      initState,
      dataProps: { hasManagedPrometheus, ...dataProps },
    } = stateAndPropsFromDataset(dataset);
    const store = createStore(initState);
    const router = createRouter(metricsDashboardBasePath);

    // eslint-disable-next-line no-new
    new Vue({
      el,
      store,
      router,
      provide: { hasManagedPrometheus },
      data() {
        return {
          dashboardProps: { ...dataProps, ...props },
        };
      },
      render(h) {
        return h('RouterView', {
          // This is attrs rather than props because:
          //  1. RouterView only actually defines one prop: `name`.
          //  2. The RouterView [throws away other props][1] given to it, in
          //     favour of those configured in the route config/params.
          //  3. The Vue template compiler itself in general compiles anything
          //     like <some-component :foo="bar" /> into roughly
          //     h('some-component', { attrs: { foo: bar } }). Then later, Vue
          //     [extract props from attrs and merges them with props][2],
          //     matching them up according to the component's definition.
          // [1]: https://github.com/vuejs/vue-router/blob/v3.4.9/src/components/view.js#L124
          // [2]: https://github.com/vuejs/vue/blob/v2.6.12/src/core/vdom/helpers/extract-props.js#L12-L50
          attrs: {
            dashboardProps: this.dashboardProps,
          },
        });
      },
    });
  }
};
