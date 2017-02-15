import PipelineStage from '../../vue_pipelines_index/components/stage';
import pipelineStatusIcon from '../../vue_shared/components/pipeline_status_icon';
import { statusClassToSvgMap } from '../../vue_shared/pipeline_svg_icons';

export default {
  name: 'MRWidgetPipeline',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'pipeline-stage': PipelineStage,
    'pipeline-status-icon': pipelineStatusIcon,
  },
  computed: {
    hasCIError() {
      const { hasCI, ciStatus } = this.mr;

      return hasCI && !ciStatus;
    },
    svg() {
      return statusClassToSvgMap.icon_status_failed;
    },
  },
  template: `
    <div class="mr-widget-heading">
      <div class="ci_widget">
        <template v-if="hasCIError">
          <div class="ci-status-icon ci-status-icon-failed js-ci-error">
            <span class="js-icon-link icon-link">
              <span v-html="svg" aria-hidden="true"></span>
            </span>
          </div>
          <span>Could not connect to the CI server. Please check your settings and try again.</span>
        </template>
        <template v-else>
          <pipeline-status-icon :pipelineStatus="mr.pipeline.details.status" />
          <span>
            Pipeline
            <a
              :href="mr.pipeline.path"
              class="pipeline-id">#{{mr.pipeline.id}}</a>
            {{mr.pipeline.details.status.label}}
          </span>
          <div class="mr-widget-pipeline-graph">
            <div class="stage-cell">
              <div class="stage-container dropdown js-mini-pipeline-graph"
                v-if="mr.pipeline.details.stages.length > 0"
                v-for="stage in mr.pipeline.details.stages">
                <pipeline-stage :stage="stage" />
              </div>
            </div>
          </div>
          <span>
            for
            <a class="monospace js-commit-link"
              :href="mr.pipeline.commit.commit_path">{{mr.pipeline.commit.short_id}}</a>.
          </span>
          <span
            v-if="mr.pipeline.coverage"
            class="js-mr-coverage">
            Coverage {{mr.pipeline.coverage}}%
          </span>
        </template>
      </div>
    </div>
  `,
};

