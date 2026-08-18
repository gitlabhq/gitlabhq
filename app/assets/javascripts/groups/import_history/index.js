import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import GroupImportHistory from './import_history.vue';

export default () => {
  const el = document.getElementById('js-group-import-history');

  if (!el) return null;

  const { groupName } = el.dataset;

  return initVueApp({
    el,
    name: 'GroupImportHistoryRoot',
    component: GroupImportHistory,
    props: {
      groupName,
    },
  });
};
