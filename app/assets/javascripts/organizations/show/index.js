import Vue from 'vue';
import App from './components/app.vue';

export const initOrganizationsShow = () => {
  const el = document.getElementById('js-organizations-show');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;
  const { organization } = JSON.parse(appData);

  return new Vue({
    el,
    name: 'OrganizationShowRoot',
    render(createElement) {
      return createElement(App, { props: { organization } });
    },
  });
};
