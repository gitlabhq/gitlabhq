import Vue from 'vue';
import App from './app.vue';

export default function initCodeDropdownClientsForm() {
  const el = document.getElementById('js-code-dropdown-clients-form');

  if (!el) return null;

  const { codeDropdownCustomClients: initial } = el.dataset;
  let initialClients = [];

  try {
    const parsed = JSON.parse(initial || '[]');
    if (Array.isArray(parsed)) initialClients = parsed;
  } catch (_e) {
    initialClients = [];
  }

  return new Vue({
    el,
    name: 'CodeDropdownClientsRoot',
    render(h) {
      return h(App, {
        props: { initialClients },
      });
    },
  });
}
