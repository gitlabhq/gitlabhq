<script>
import { mapActions, mapState } from 'vuex';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';
import List from './list.vue';
import { scopes } from '../../stores/modules/merge_requests/constants';

export default {
  components: {
    Tabs,
    Tab,
    List,
  },
  data() {
    return {
      activeTabIndex: 0,
    };
  },
  computed: {
    ...mapState('mergeRequests', ['isLoading', 'mergeRequests']),
    ...mapState(['currentMergeRequestId']),
    tabScope() {
      return this.activeTabIndex === 0 ? scopes.createdByMe : scopes.assignedToMe;
    },
  },
  mounted() {
    this.fetchMergeRequests();
  },
  methods: {
    ...mapActions('mergeRequests', ['fetchMergeRequests', 'setScope']),
    updateActiveTab(index) {
      this.activeTabIndex = index;

      this.setScope(this.tabScope);
      this.fetchMergeRequests();
    },
  },
};
</script>

<template>
  <div class="dropdown-menu">
    <tabs
      stop-propagation
      @changed="updateActiveTab"
    >
      <tab
        :title="__('Created by me')"
        active
      >
        <list
          v-if="activeTabIndex === 0"
          :is-loading="isLoading"
          :items="mergeRequests"
          :current-id="currentMergeRequestId"
          @search="fetchMergeRequests"
        />
      </tab>
      <tab :title="__('Assigned to me')">
        <list
          v-if="activeTabIndex === 1"
          :is-loading="isLoading"
          :items="mergeRequests"
          :current-id="currentMergeRequestId"
          @search="fetchMergeRequests"
        />
      </tab>
    </tabs>
  </div>
</template>

<style scoped>
.dropdown-menu {
  width: 400px;
  padding: 0;
  max-height: initial !important;
}
</style>
