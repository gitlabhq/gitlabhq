import Vue from 'vue';
import GroupImportHistory from './import_history.vue';

export default () => {
  const el = document.getElementById('js-group-import-history');

  if (!el) return null;

  const { groupName } = el.dataset;

  return new Vue({
    el,
    name: 'GroupImportHistoryRoot',
    render(h) {
      return h(GroupImportHistory, {
        props: {
          groupName,
        },
      });
    },
  });
};
