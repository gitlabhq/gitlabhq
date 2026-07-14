import { computed, ref } from 'vue';
import { uniqBy } from 'lodash-es';
import { defineStore } from 'pinia';
import { useCommitModalState } from './composables/use_commit_modal_state';

export const useCherryPickCommit = defineStore('cherryPickCommit', () => {
  const modalState = useCommitModalState();
  const projects = ref([]);
  const targetProjectId = ref('');
  const targetProjectName = ref('');

  const sortedProjects = computed(() => uniqBy(projects.value, 'id').sort());

  const setSelectedProject = (id) => {
    let branchesEndpoint = modalState.branchesEndpoint.value;

    if (projects.value?.length) {
      branchesEndpoint = projects.value.find((project) => project.id === id).refsUrl;
    }

    targetProjectId.value = id;
    modalState.branch.value = modalState.defaultBranch.value;
    modalState.setBranchesEndpoint(branchesEndpoint);
    modalState.fetchBranches();
  };

  return {
    ...modalState,
    projects,
    targetProjectId,
    targetProjectName,
    sortedProjects,
    setSelectedProject,
  };
});
