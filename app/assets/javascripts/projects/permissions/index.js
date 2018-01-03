import Vue from 'vue';
import settingsPanel from './components/settings_panel.vue';

export default function initProjectPermissionsSettings() {
  const mountPoint = document.querySelector('.js-project-permissions-form');
  const componentPropsEl = document.querySelector('.js-project-permissions-form-data');
  const componentProps = JSON.parse(componentPropsEl.innerHTML);

  return new Vue({
    el: mountPoint,
    render: createElement => createElement(settingsPanel, { props: { ...componentProps } }),
  });
}
