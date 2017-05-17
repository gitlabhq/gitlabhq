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
      return this.mr.pipeline.details.stages.length > 1 ? 'stages' : 'stage';
    },
    status() {
      return this.mr.pipeline.details.status || {};
    },
    statusPath() {
      return this.status ? this.status.details_path : '';
    },
  },
  template: `
    <div class="mr-widget-heading">
      <div class="ci-widget">
        <template v-if="hasCIError">
          <div class="ci-status-icon ci-status-icon-failed ci-error js-ci-error">
            <span class="js-icon-link icon-link">
              <span
                v-html="svg"
                aria-hidden="true"></span>
            </span>
          </div>
          <span>Could not connect to the CI server. Please check your settings and try again.</span>
        </template>
        <template v-else>
          <div>
            <a
              class="icon-link"
              :href="statusPath">
              <ci-icon :status="status" />
            </a>
          </div>
          <span>
            Pipeline
            <a
              :href="mr.pipeline.path"
              class="pipeline-id">#{{mr.pipeline.id}}</a>
            {{mr.pipeline.details.status.label}}
          </span>
          <span
            v-if="mr.pipeline.details.stages.length > 0">
            with {{stageText}}
          </span>
          <div class="mr-widget-pipeline-graph">
            <div class="stage-cell">
              <div
                v-if="mr.pipeline.details.stages.length > 0"
                v-for="stage in mr.pipeline.details.stages"
                class="stage-container dropdown js-mini-pipeline-graph">
                <pipeline-stage :stage="stage" />
              </div>
            </div>
          </div>
          <span>
            for
            <a
              :href="mr.pipeline.commit.commit_path"
              class="commit-sha js-commit-link">
              {{mr.pipeline.commit.short_id}}</a>.
          </span>
          <span
            v-if="mr.pipeline.coverage"
            class="js-mr-coverage">
            Coverage {{mr.pipeline.coverage}}%.
          </span>
        </template>
      </div>
    </div>
  `,
};
