import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import UnarchiveSettings from '~/groups_projects/unarchive/components/unarchive_settings.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default function initUnarchiveSettings() {
  const el = document.getElementById('js-unarchive-settings');
  if (!el) return null;

  const { resourceType, resourceId, resourcePath, ancestorsArchived, helpPath } = el.dataset;

  return initVueApp({
    el,
    name: 'UnarchiveSettingsRoot',
    component: UnarchiveSettings,
    props: {
      ancestorsArchived: parseBoolean(ancestorsArchived),
      resourceType,
      resourceId,
      resourcePath,
      helpPath,
    },
  });
}
