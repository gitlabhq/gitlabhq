import Vue from 'vue';
import App from './components/app.vue';

function initJiraConnect() {
  const el = document.querySelector('.js-jira-connect-app');

  return new Vue({
    el,
    render(createElement) {
      return createElement(App, {});
    },
  });
}

document.addEventListener('DOMContentLoaded', initJiraConnect);
