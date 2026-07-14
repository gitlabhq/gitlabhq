import { defineStore } from 'pinia';
import { useCommitModalState } from './composables/use_commit_modal_state';

export const useProjectCommit = defineStore('projectCommit', () => useCommitModalState());
