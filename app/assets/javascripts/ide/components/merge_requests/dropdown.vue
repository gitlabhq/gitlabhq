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
  props: {
    show: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapGetters('mergeRequests', ['assignedData', 'createdData']),
    createdMergeRequestLength() {
      return this.createdData.mergeRequests.length;
    },
    assignedMergeRequestLength() {
      return this.assignedData.mergeRequests.length;
    },
  },
};
</script>

<template>
  <div class="dropdown-menu ide-merge-requests-dropdown p-0">
    <tabs
      v-if="show"
      stop-propagation
    >
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
        />
      </tab>
      <tab>
        <template slot="title">
          {{ __('Assigned to me') }}
          <span class="badge badge-pill">
            {{ assignedMergeRequestLength }}
          </span>
        </template>
        <list
          type="assigned"
          :empty-text="__('You do not have any assigned merge requests')"
        />
      </tab>
    </tabs>
  </div>
</template>
