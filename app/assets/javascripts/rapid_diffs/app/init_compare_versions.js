import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import CompareVersions from './compare_versions/compare_versions.vue';
import CommitNavigation from './compare_versions/commit_navigation.vue';

export const initCompareVersions = (el, appData) => {
  const {
    source_versions: sourceVersions,
    target_versions: targetVersions,
    commit,
  } = appData.versions;
  const versionsStore = useMergeRequestVersions(pinia);

  versionsStore.setVersions({ sourceVersions, targetVersions });

  if (commit) {
    versionsStore.setCommit(commit);
  }

  return new Vue({
    el,
    name: 'CompareVersionsRoot',
    render(h) {
      if (versionsStore.commitId) {
        return h(CommitNavigation, {
          props: {
            commit,
          },
        });
      }

      return h(CompareVersions, {
        props: {
          sourceVersions: versionsStore.sourceVersions,
          targetVersions: versionsStore.targetVersions,
        },
      });
    },
  });
};
