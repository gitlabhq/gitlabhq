import Vue from 'vue';
import ObservabilityApp from './components/app.vue';

export default () => {
  const el = document.getElementById('js-observability');
  if (!el) return null;
  const { dataset } = el;

  const authTokens = {};
  for (const key in dataset) {
    if (key.startsWith('authTokens')) {
      const newKey = key.replace(/^authTokens/, '');
      const formattedKey = newKey.charAt(0).toLowerCase() + newKey.slice(1);
      authTokens[formattedKey] = dataset[key];
    }
  }

  return new Vue({
    el,
    render(h) {
      return h(ObservabilityApp, {
        props: {
          o11yUrl: dataset.o11yUrl,
          path: dataset.path,
          authTokens,
          title: dataset.title,
        },
      });
    },
  });
};
