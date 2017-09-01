import PipelineStage from '../../pipelines/components/stage.vue';
import ciIcon from '../../vue_shared/components/ci_icon.vue';
import { statusIconEntityMap } from '../../vue_shared/ci_status_icons';

export default {
  name: 'MRWidgetPipeline',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'pipeline-stage': PipelineStage,
    ciIcon,
  },
  computed: {
    hasCIError() {
      const { hasCI, ciStatus } = this.mr;

      return hasCI && !ciStatus;
    },
    svg() {
      return statusIconEntityMap.icon_status_failed;
    },
    stageText() {
      let stageText = 'stage';
      if (
        this.mr.pipeline &&
        this.mr.pipeline.details &&
        this.mr.pipeline.details.stages &&
        this.mr.pipeline.details.stages.length > 1
      ) {
        stageText = 'stages';
      }

      return stageText;
    },
    stages() {
      let stages = [];
      if (this.mr.pipeline.details && this.mr.pipeline.details.stages) {
        stages = this.mr.pipeline.details.stages;
      }

      return stages;
    },
    status() {
      console.log('mr', this.mr);
      console.log('mr pipeline', this.mr.pipeline);
      let status = {
        group: this.mr.ciStatus,
      };
      if (this.mr.pipeline && this.mr.pipeline.details) {
        status = this.mr.pipeline.details.status;
      }

      console.log('mr status', status);
      return status;
    },
  },
  template: `
    <div class="mr-widget-heading">
      <div class="ci-widget media">
        <template v-if="hasCIError">
          <div class="ci-status-icon ci-status-icon-failed ci-error js-ci-error append-right-10">
            <span
              v-html="svg"
              aria-hidden="true"></span>
          </div>
          <div class="media-body">
            Could not connect to the CI server. Please check your settings and try again
          </div>
        </template>
        <template v-else>
          <div class="ci-status-icon append-right-10">
            <a
              class="icon-link"
              :href="status.details_path">
              <ci-icon :status="status" />
            </a>
          </div>
          <div class="media-body">
            <span v-if="mr.pipeline.id">
              Pipeline
              <a
                :href="mr.pipeline.path"
                class="pipeline-id">#{{mr.pipeline.id}}</a>
            </span>
            <span v-else>
              External pipeline
            </span>
            <span
              v-if="stages.length > 0"
              class="mr-widget-pipeline-graph">
              <span class="stage-cell">
                <div
                  v-for="stage in stages"
                  class="stage-container dropdown js-mini-pipeline-graph">
                  <pipeline-stage :stage="stage" />
                </div>
              </span>
            </span>
            <span v-else>
              <pipeline-stage :stage="status" disable-dropdown="true" />
            </span>
            <span>
              {{status.label}}
              <template v-if="mr.pipeline.commit">for
                <a
                  :href="mr.pipeline.commit.commit_path"
                  class="commit-sha js-commit-link">
                  {{mr.pipeline.commit.short_id}}</a>.
              </template>
            </span>
            <span
              v-if="mr.pipeline.coverage"
              class="js-mr-coverage">
              Coverage {{mr.pipeline.coverage}}%
            </span>
          </div>
        </template>
      </div>
    </div>
  `,
};
