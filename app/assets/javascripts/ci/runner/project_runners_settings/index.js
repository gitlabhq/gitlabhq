import Vue from 'vue';
import ProjectRunnersSettingsApp from './project_runners_settings_app.vue';

export const initProjectRunnersSettings = (selector = '#js-project-runners-settings') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    render(h) {
      return h(ProjectRunnersSettingsApp, {});
    },
  });
};
