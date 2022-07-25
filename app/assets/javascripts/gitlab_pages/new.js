import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import createDefaultClient from '~/lib/graphql';
import Pages from './components/pages_pipeline_wizard.vue';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      batchMax: 1,
      assumeImmutableResults: true,
    },
  ),
});

export default function initPages() {
  const el = document.querySelector('#js-pages');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    name: 'GitlabPagesNewRoot',
    apolloProvider,
    render(createElement) {
      return createElement(Pages, {
        props: {
          ...el.dataset,
        },
      });
    },
  });
}
