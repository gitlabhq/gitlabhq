<script>
import Vue from 'vue';
import Vuex from 'vuex';
import storeOptions from '../stores/issue_notes_store';

Vue.use(Vuex);
const store = new Vuex.Store(storeOptions);

export default {
  name: 'IssueNotes',
  store,
  data() {
    return {
      isLoading: true,
    };
  },
  mounted() {
    const path = this.$el.parentNode.dataset.discussionsPath;
    this.$store.dispatch('fetchNotes', path)
      .finally(() => {
        this.isLoading = false;
      });
  },
};
</script>

<template>
  <div id="notes">
    <div
      v-if="isLoading"
      class="loading">
      <i
        aria-hidden="true"
        class="fa fa-spinner fa-spin" />
    </div>
  </div>
</template>
