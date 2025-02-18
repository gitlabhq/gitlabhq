import Vue from 'vue';
import CredentialsFilterApp from './components/credentials_filter_app.vue';

export const initCredentialsFilterApp = () => {
  return new Vue({
    el: document.querySelector('#js-credentials-filter-app'),
    render: (createElement) => createElement(CredentialsFilterApp),
  });
};
