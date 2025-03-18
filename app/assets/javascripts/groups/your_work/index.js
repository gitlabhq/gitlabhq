import Vue from 'vue';
import YourWorkGroupsApp from './components/app.vue';

export const initYourWorkGroups = () => {
  const el = document.getElementById('js-your-work-groups-app');

  if (!el) return false;

  return new Vue({
    el,
    name: 'YourWorkGroupsRoot',
    render(createElement) {
      return createElement(YourWorkGroupsApp);
    },
  });
};
