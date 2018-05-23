<script>
import { mapActions, mapGetters } from 'vuex';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';

export default {
  components: {
    Tabs,
    Tab,
  },
  computed: {
    ...mapGetters('pipelines', ['jobsCount', 'failedJobs']),
  },
  mounted() {
    this.fetchJobs();
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobs']),
  },
};
</script>

<template>
  <div>
    <tabs>
      <tab active>
        <template slot="title">
          Jobs <span class="badge">{{ jobsCount }}</span>
        </template>
        List all jobs here
      </tab>
      <tab>
        <template slot="title">
          Failed Jobs <span class="badge">{{ failedJobs.length }}</span>
        </template>
        List all failed jobs here
      </tab>
    </tabs>
  </div>
</template>
