import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { GlTabsBehavior } from '~/tabs';
import QuickStartSnippets from '~/observability/setup/components/quick_start_snippets.vue';

Vue.use(GlToast);

const tabNavs = document.querySelectorAll('.js-o11y-endpoint-tabs, .js-o11y-curl-tabs');
tabNavs.forEach((el) => new GlTabsBehavior(el));

const initQuickStartSnippets = () => {
  const el = document.getElementById('js-observability-quick-start');
  if (!el) return null;

  const { endpoint } = el.dataset;

  return new Vue({
    el,
    name: 'ObservabilityQuickStartRoot',
    render(h) {
      return h(QuickStartSnippets, {
        props: { endpoint },
      });
    },
  });
};

initQuickStartSnippets();
