import PipelineStage from '../../vue_pipelines_index/components/stage';
import pipelineStatusIcon from '../../vue_shared/components/pipeline_status_icon';

export default {
  name: 'MRWidgetPipeline',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'pipeline-stage': PipelineStage,
    'pipeline-status-icon': pipelineStatusIcon,
  },
  template: `
    <div class="mr-widget-heading">
      <div class="ci_widget">
        <pipeline-status-icon :pipelineStatus="mr.pipeline.details.status" />
        <span>
          Pipeline
          <a :href="mr.pipeline.path">#{{mr.pipeline.id}}</a>
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
      </div>
    </div>
  `,
};

