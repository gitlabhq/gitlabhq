import PipelineStage from '../../pipelines/components/stage.vue';
import ciIcon from '../../vue_shared/components/ci_icon.vue';
import { statusIconEntityMap } from '../../vue_shared/ci_status_icons';
import linkedPipelinesMiniList from '../../vue_shared/components/linked_pipelines_mini_list.vue';

export default {
  name: 'MRWidgetPipeline',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'pipeline-stage': PipelineStage,
    ciIcon,
    linkedPipelinesMiniList,
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

    /* We typically set defaults ([]) in the store or prop declarations, but because triggered
     * and triggeredBy are appended to `pipeline`, we can't set defaults in the store, and we
     * need to check their length here to prevent initializing linked-pipeline-mini-lists
     * unneccessarily. */

    triggered() {
      return this.mr.pipeline.triggered || [];
    },
    triggeredBy() {
      const response = this.mr.pipeline.triggered_by;
      return response ? [response] : [];
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
              :href="this.status.details_path">
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
              <linked-pipelines-mini-list
                v-if="triggeredBy.length"
                :triggered-by="triggeredBy"
                />

              <div
                v-if="mr.pipeline.details.stages.length > 0"
                v-for="(stage, index) in mr.pipeline.details.stages"
                class="stage-container dropdown js-mini-pipeline-graph"
                :class="{
                  'has-downstream': index === mr.pipeline.details.stages.length - 1 && triggered.length
                }">
                <pipeline-stage :stage="stage" />
              </div>

              <linked-pipelines-mini-list
                v-if="triggered.length"
                :triggered="triggered"
                />
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
