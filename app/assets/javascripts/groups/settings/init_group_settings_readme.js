import Vue from 'vue';
import GroupSettingsReadme from './components/group_settings_readme.vue';

export const initGroupSettingsReadme = () => {
  const el = document.getElementById('js-group-settings-readme');

  if (!el) return false;

  const { groupReadmePath, readmeProjectPath, groupPath, groupId } = el.dataset;

  return new Vue({
    el,
    name: 'GroupSettingsReadmeRoot',
    render(createElement) {
      return createElement(GroupSettingsReadme, {
        props: {
          groupReadmePath,
          readmeProjectPath,
          groupPath,
          groupId,
        },
      });
    },
  });
};
