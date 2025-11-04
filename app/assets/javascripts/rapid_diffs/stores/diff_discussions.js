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
    toggleDiscussionReplies(discussion) {
      // eslint-disable-next-line no-param-reassign
      discussion.repliesCollapsed = !discussion.repliesCollapsed;
    },
    expandDiscussionReplies(discussion) {
      // eslint-disable-next-line no-param-reassign
      discussion.repliesCollapsed = false;
    },
    // eslint-disable-next-line no-unused-vars
    saveNote(endpoint, data) {
      return new Promise();
    },
  },
  getters: {
    getDiscussionById() {
      return (id) => this.discussions.find((discussion) => discussion.id === id);
    },
  },
});
