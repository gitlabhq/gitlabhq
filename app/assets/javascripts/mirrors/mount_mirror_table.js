import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import MirrorTable from 'ee_else_ce/mirrors/components/mirror_table.vue';

export default function mountMirrorTable() {
  const el = document.getElementById('js-mirror-table');
  if (!el) return null;

  const { mirrors, projectId, settingsEnabled, repositoryMirrorsAvailable, pullMirror } =
    el.dataset;

  return new Vue({
    el,
    name: 'MirrorTableRoot',
    provide: {
      projectId: Number(projectId),
      settingsEnabled: settingsEnabled === 'true',
      repositoryMirrorsAvailable: repositoryMirrorsAvailable === 'true',
    },
    render(h) {
      return h(MirrorTable, {
        props: {
          initialMirrors: convertObjectPropsToCamelCase(JSON.parse(mirrors), { deep: true }),
          initialPullMirror: pullMirror
            ? convertObjectPropsToCamelCase(JSON.parse(pullMirror), { deep: true })
            : null,
        },
      });
    },
  });
}
