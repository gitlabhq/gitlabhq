import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { GlTabsBehavior } from '~/tabs';
import QuickStartSnippets from '~/observability/setup/components/quick_start_snippets.vue';

const tabNavs = document.querySelectorAll('.js-o11y-endpoint-tabs, .js-o11y-curl-tabs');
tabNavs.forEach((el) => new GlTabsBehavior(el));

const initQuickStartSnippets = () => {
  const el = document.getElementById('js-observability-quick-start');
  if (!el) return null;

  const { endpoint } = el.dataset;

  return initVueApp({
    el,
    name: 'ObservabilityQuickStartRoot',
    component: QuickStartSnippets,
    props: { endpoint },
  });
};

initQuickStartSnippets();
