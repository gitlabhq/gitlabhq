import { defineStore } from 'pinia';
import axios from '~/lib/utils/axios_utils';

export const useDiffDiscussions = defineStore('diffDiscussions', {
  state() {
    return {
      discussions: [],
    };
  },
  actions: {
    async fetchDiscussions(url) {
      const response = await axios.get(url);
      this.discussions = response.data.discussions;
    },
  },
  getters: {
    getDiscussionById() {
      return (id) => this.discussions.find((discussion) => discussion.id === id);
    },
  },
});
