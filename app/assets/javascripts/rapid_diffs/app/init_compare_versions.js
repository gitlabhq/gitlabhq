import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import CompareVersions from './compare_versions/compare_versions.vue';

export const initCompareVersions = (el, appData) => {
  const { source_versions: sourceVersions, target_versions: targetVersions } = appData.versions;
  const versionsStore = useMergeRequestVersions(pinia);

  versionsStore.setVersions({ sourceVersions, targetVersions });

  return new Vue({
    el,
    name: 'CompareVersionsRoot',
    render(h) {
      return h(CompareVersions, {
        props: {
          sourceVersions: versionsStore.sourceVersions,
          targetVersions: versionsStore.targetVersions,
        },
      });
    },
  });
};
