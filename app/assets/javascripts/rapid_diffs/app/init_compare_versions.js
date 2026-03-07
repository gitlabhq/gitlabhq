import Vue from 'vue';
import CompareVersions from './compare_versions/compare_versions.vue';

export const initCompareVersions = (el, appData) => {
  const { source_versions: sourceVersions, target_versions: targetVersions } = appData.versions;

  return new Vue({
    el,
    name: 'CompareVersionsRoot',
    render(h) {
      return h(CompareVersions, {
        props: {
          sourceVersions,
          targetVersions,
        },
      });
    },
  });
};
