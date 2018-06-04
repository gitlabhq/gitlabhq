<script>
import { mapGetters } from 'vuex';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';
import List from './list.vue';

export default {
  components: {
    Tabs,
    Tab,
    List,
  },
  computed: {
    ...mapGetters('mergeRequests', ['assignedData', 'createdData']),
    createdMergeRequestLength() {
      return this.createdData.mergeRequests.length;
    },
  },
  methods: {
    hideDropdown() {
      this.$emit('hide');
    },
  },
};
</script>

<template>
  <div class="dropdown-menu ide-merge-requests-dropdown">
    <tabs stop-propagation>
      <tab active>
        <template slot="title">
          {{ __('Created by me') }}
          <span class="badge badge-pill">
            {{ createdMergeRequestLength }}
          </span>
        </template>
        <list
          type="created"
          :empty-text="__('You have not created any merge requests')"
          @hide="hideDropdown"
        />
      </tab>
      <tab>
        <template slot="title">
          {{ __('Assigned to me') }}
          <span class="badge badge-pill">
            {{ assignedData.mergeRequests.length }}
          </span>
        </template>
        <list
          type="assigned"
          :empty-text="__('You do not have any assigned merge requests')"
          @hide="hideDropdown"
        />
      </tab>
    </tabs>
  </div>
</template>

<style scoped>
.dropdown-menu {
  width: 350px;
  padding: 0;
  max-height: initial !important;
}
</style>
