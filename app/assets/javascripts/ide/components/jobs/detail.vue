<script>
import { mapState } from 'vuex';
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';
import Job from '../../../job';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
  },
  computed: {
    ...mapState('pipelines', ['detailJob']),
    rawUrl() {
      return `${this.detailJob.path}/raw`;
    },
  },
  mounted() {
    this.job = new Job({
      buildStage: 'a',
      buildState: this.detailJob.status.text,
      pagePath: this.detailJob.path,
      redirectToJob: false,
    });
  },
  beforeDestroy() {
    this.job.destroy();
  },
};
</script>

<template>
  <div class="ide-pipeline build-page">
    <header
      class="ide-tree-header ide-pipeline-header"
    >
      <button
        class="btn btn-default btn-sm"
        @click="() => { $store.state.pipelines.detailJob = null; $store.dispatch('setRightPane', 'pipelines-list') }"
      >
        <icon
          name="chevron-left"
        />
        {{ __('View jobs') }}
      </button>
    </header>
    <div class="build-trace-container prepend-top-default">
      <div
        v-once
        class="top-bar js-top-bar"
      >
        <div class="controllers float-right">
          <a
            v-tooltip
            :title="__('Show complete raw')"
            data-placement="top"
            data-container="body"
            class="js-raw-link-controller controllers-buttons"
            :href="rawUrl"
          >
            <i
              aria-hidden="true"
              class="fa fa-file-text-o"
            ></i>
          </a>
          <div
            v-tooltip
            class="controllers-buttons"
            data-container="body"
            data-placement="top"
            :title="__('Scroll to top')"
          >
            <button
              class="js-scroll-up btn-scroll btn-transparent btn-blank"
              disabled
              type="button"
            >
              <icon
                name="scroll_up"
              />
            </button>
          </div>
          <div
            v-tooltip
            class="controllers-buttons"
            data-container="body"
            data-placement="top"
            :title="__('Scroll to top')"
          >
            <button
              class="js-scroll-up btn-scroll btn-transparent btn-blank"
              disabled
              type="button"
            >
              <icon
                name="scroll_down"
              />
            </button>
          </div>
        </div>
      </div>
      <pre
        class="build-trace"
        id="build-trace"
      >
        <code class="bash js-build-output">
        </code>
      </pre>
    </div>
  </div>
</template>

<style scoped>
.build-trace-container {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.ide-tree-header .btn {
  display: flex;
}
</style>