import { computed, ref } from 'vue';
import { uniq } from 'lodash-es';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { PROJECT_BRANCHES_ERROR } from '../../constants';

export const useCommitModalState = () => {
  const endpoint = ref(null);
  const branchesEndpoint = ref(null);
  const isFetching = ref(false);
  const branches = ref([]);
  const pushCode = ref(false);
  const branchCollaboration = ref(false);
  const modalTitle = ref('');
  const existingBranch = ref('');
  const defaultBranch = ref('');
  const branch = ref('');

  const joinedBranches = computed(() => uniq(branches.value).sort());

  const clearModal = () => {
    branch.value = defaultBranch.value;
  };

  const setBranchesEndpoint = (newEndpoint) => {
    branchesEndpoint.value = newEndpoint;
  };

  const fetchBranches = async (query) => {
    isFetching.value = true;

    try {
      const { data = [] } = await axios.get(branchesEndpoint.value, {
        params: { search: query },
      });

      branches.value = data.Branches?.length ? data.Branches : data;
      branches.value.unshift(branch.value);
    } catch {
      createAlert({ message: PROJECT_BRANCHES_ERROR });
    } finally {
      isFetching.value = false;
    }
  };

  const setBranch = (newBranch) => {
    branch.value = newBranch;
  };

  return {
    endpoint,
    branchesEndpoint,
    isFetching,
    branches,
    pushCode,
    branchCollaboration,
    modalTitle,
    existingBranch,
    defaultBranch,
    branch,
    joinedBranches,
    clearModal,
    setBranchesEndpoint,
    fetchBranches,
    setBranch,
  };
};
