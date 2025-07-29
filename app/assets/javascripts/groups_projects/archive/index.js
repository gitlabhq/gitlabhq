import Vue from 'vue';
import ArchiveSettings from '~/groups_projects/archive/components/archive_settings.vue';

export default function initArchiveSettings() {
  const el = document.getElementById('js-archive-settings');
  if (!el) return null;

  return new Vue({
    el,
    name: 'ArchiveSettingsRoot',
    render(createElement) {
      return createElement(ArchiveSettings, { props: el.dataset });
    },
  });
}
