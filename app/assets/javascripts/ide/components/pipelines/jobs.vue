<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';
import JobsList from '../jobs/list.vue';

export default {
  components: {
    Tabs,
    Tab,
    JobsList,
  },
  computed: {
    ...mapGetters('pipelines', ['jobsCount', 'failedJobsCount', 'failedStages']),
    ...mapState('pipelines', ['stages', 'isLoadingJobs']),
  },
  created() {
    this.fetchStages();
  },
  methods: {
    ...mapActions('pipelines', ['fetchStages']),
  },
};
</script>

<template>
  <div>
    <tabs>
      <tab active>
        <template slot="title">
          Jobs
          <span
            v-if="!isLoadingJobs || jobsCount"
            class="badge"
          >
            {{ jobsCount }}
          </span>
        </template>
        <jobs-list
          :stages="stages"
        />
      </tab>
      <tab>
        <template slot="title">
          Failed Jobs
          <span
            v-if="!isLoadingJobs || failedJobsCount"
            class="badge"
          >
            {{ failedJobsCount }}
          </span>
        </template>
        <jobs-list
          :stages="failedStages"
        />
      </tab>
    </tabs>
  </div>
</template>
