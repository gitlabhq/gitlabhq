<script>
import { mapActions } from 'vuex';
import Icon from '../../../vue_shared/components/icon.vue';
import CiIcon from '../../../vue_shared/components/ci_icon.vue';
import LoadingIcon from '../../../vue_shared/components/loading_icon.vue';

export default {
  components: {
    Icon,
    CiIcon,
    LoadingIcon,
  },
  props: {
    stage: {
      type: Object,
      required: true,
    },
  },
  computed: {
    collapseIcon() {
      return this.stage.isCollapsed ? 'angle-left' : 'angle-down';
    },
  },
  created() {
    this.fetchJobs(this.stage);
  },
  methods: {
    ...mapActions('pipelines', ['fetchJobs']),
  },
};
</script>

<template>
  <div
    class="panel panel-default prepend-top-default"
  >
    <div
      class="panel-heading"
      @click="() => stage.isCollapsed = !stage.isCollapsed"
    >
      <ci-icon
        :status="stage.status"
      />
      <span class="prepend-left-8">
        {{ stage.title }}
      </span>
      <div>
        <span class="badge">
          {{ stage.jobs.length }}
        </span>
      </div>
      <icon
        :name="collapseIcon"
        css-classes="pull-right"
      />
    </div>
    <div
      class="panel-body"
      v-show="!stage.isCollapsed"
    >
      <loading-icon
        v-if="stage.isLoading && !stage.jobs.length"
      />
      <template v-else>
        <div
          v-for="job in stage.jobs"
          :key="job.id"
        >
          <ci-icon :status="job.status" />
          {{ job.name }}
          <a
            :href="job.build_path"
            target="_blank"
          >#{{ job.id }}</a>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.panel-heading {
  display: flex;
  cursor: pointer;
}
.panel-heading .ci-status-icon {
  display: flex;
  align-items: center;
}

.panel-heading .pull-right {
  margin: auto 0 auto auto;
}
</style>
