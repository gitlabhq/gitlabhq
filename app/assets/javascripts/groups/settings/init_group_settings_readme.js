import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import GroupSettingsReadme from './components/group_settings_readme.vue';

export const initGroupSettingsReadme = () => {
  const el = document.getElementById('js-group-settings-readme');

  if (!el) return false;

  const { groupReadmePath, readmeProjectPath, groupPath, groupId } = el.dataset;

  return initVueApp({
    el,
    name: 'GroupSettingsReadmeRoot',
    component: GroupSettingsReadme,
    props: {
      groupReadmePath,
      readmeProjectPath,
      groupPath,
      groupId,
    },
  });
};
