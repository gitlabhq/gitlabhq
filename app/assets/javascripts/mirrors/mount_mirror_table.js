import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import MirrorTable from 'ee_else_ce/mirrors/components/mirror_table.vue';

export default function mountMirrorTable() {
  const el = document.getElementById('js-mirror-table');
  if (!el) return null;

  const { mirrors, projectId, settingsEnabled, repositoryMirrorsAvailable, pullMirror } =
    el.dataset;

  return initVueApp({
    el,
    name: 'MirrorTableRoot',
    provide: {
      projectId: Number(projectId),
      settingsEnabled: settingsEnabled === 'true',
      repositoryMirrorsAvailable: repositoryMirrorsAvailable === 'true',
    },
    component: MirrorTable,
    props: {
      initialMirrors: convertObjectPropsToCamelCase(JSON.parse(mirrors), { deep: true }),
      initialPullMirror: pullMirror
        ? convertObjectPropsToCamelCase(JSON.parse(pullMirror), { deep: true })
        : null,
    },
  });
}
