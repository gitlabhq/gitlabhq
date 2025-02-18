import { defineStore } from 'pinia';
import types from '~/mr_notes/stores/mutation_types';
import axios from '~/lib/utils/axios_utils';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import mrNotes from '~/mr_notes/stores';

export const useMrNotes = defineStore('legacyMrNotes', {
  syncWith: {
    store: mrNotes,
    namespace: 'page',
  },
  state() {
    return {
      endpoints: {},
      activeTab: null,
      mrMetadata: {},
      failedToLoadMetadata: false,
    };
  },
  actions: {
    setActiveTab(tab) {
      this[types.SET_ACTIVE_TAB](tab);
    },
    setEndpoints(endpoints) {
      this[types.SET_ENDPOINTS](endpoints);
    },
    async fetchMrMetadata() {
      if (this.endpoints?.metadata) {
        this[types.SET_FAILED_TO_LOAD_METADATA](false);
        try {
          const { data } = await axios.get(this.endpoints.metadata);
          this[types.SET_MR_METADATA](data);
        } catch (error) {
          this[types.SET_FAILED_TO_LOAD_METADATA](true);
        }
      }
    },
    toggleAllVisibleDiscussions() {
      if (this.isDiffsPage) {
        useLegacyDiffs().toggleAllDiffDiscussions();
      } else {
        useNotes().toggleAllDiscussions();
      }
    },
    [types.SET_ACTIVE_TAB](tab) {
      this.activeTab = tab;
    },
    [types.SET_ENDPOINTS](endpoints) {
      this.endpoints = endpoints;
    },
    [types.SET_MR_METADATA](metadata) {
      this.mrMetadata = metadata;
    },
    [types.SET_FAILED_TO_LOAD_METADATA](value) {
      this.failedToLoadMetadata = value;
    },
  },
  getters: {
    isLoggedIn() {
      return Boolean(useNotes().getUserData.id);
    },
    isDiffsPage() {
      return this.activeTab === 'diffs';
    },
    allVisibleDiscussionsExpanded() {
      if (this.isDiffsPage) return useLegacyDiffs().allDiffDiscussionsExpanded;
      return useNotes().allDiscussionsExpanded;
    },
  },
});
