import { defineStore } from 'pinia';
import { useCommitModalState } from './composables/use_commit_modal_state';

export const useRevertCommit = defineStore('revertCommit', () => useCommitModalState());
