<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import Icon from '../../../vue_shared/components/icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import Tabs from '../../../vue_shared/components/tabs/tabs';
import Tab from '../../../vue_shared/components/tabs/tab.vue';

export default {
  components: {
    Tabs,
    Tab,
    Icon,
    CiIcon,
  },
  computed: {
    ...mapGetters('pipelines', ['jobsCount', 'failedJobsCount']),
    ...mapState('pipelines', ['stages']),
  },
  mounted() {
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
          Jobs <span class="badge">{{ jobsCount }}</span>
        </template>
        <div style="overflow: auto;">
          <div
            v-for="stage in stages"
            :key="stage.id"
            class="panel panel-default"
          >
            <div
              class="panel-heading"
              @click="() => stage.isCollapsed = !stage.isCollapsed"
            >
              <ci-icon :status="stage.status" />
              {{ stage.title }}
              <span class="badge">
                {{ stage.jobs.length }}
              </span>
              <icon
                :name="stage.isCollapsed ? 'angle-left' : 'angle-down'"
                css-classes="pull-right"
              />
            </div>
            <div
              class="panel-body"
              v-show="!stage.isCollapsed"
            >
              <div
                v-for="job in stage.jobs"
                :key="job.id"
              >
                <ci-icon :status="job.status" />
                {{ job.name }} #{{ job.id }}
              </div>
            </div>
          </div>
        </div>
      </tab>
      <tab>
        <template slot="title">
          Failed Jobs <span class="badge">{{ failedJobsCount }}</span>
        </template>
        List all failed jobs here
      </tab>
    </tabs>
  </div>
</template>
