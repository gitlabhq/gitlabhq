import Vue from 'vue';
import ArchiveSettings from '~/groups_projects/archive/components/archive_settings.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default function initArchiveSettings() {
  const el = document.getElementById('js-archive-settings');

  if (!el) return null;

  const { resourceType, resourceId, resourcePath, markedForDeletion, helpPath } = el.dataset;

  return new Vue({
    el,
    name: 'ArchiveSettingsRoot',
    render(createElement) {
      return createElement(ArchiveSettings, {
        props: {
          resourceType,
          resourceId,
          resourcePath,
          markedForDeletion: parseBoolean(markedForDeletion),
          helpPath,
        },
      });
    },
  });
}
