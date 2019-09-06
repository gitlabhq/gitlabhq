<script>
import { GlLoadingIcon } from '@gitlab/ui';
import StageColumnComponent from './stage_column_component.vue';
import GraphMixin from '../../mixins/graph_component_mixin';

export default {
  components: {
    StageColumnComponent,
    GlLoadingIcon,
  },
  mixins: [GraphMixin],
};
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div class="pipeline-visualization pipeline-graph pipeline-tab-content">
      <div v-if="isLoading" class="m-auto"><gl-loading-icon :size="3" /></div>

      <ul v-if="!isLoading" class="stage-column-list">
        <stage-column-component
          v-for="(stage, index) in graph"
          :key="stage.name"
          :class="{
            'append-right-48': shouldAddRightMargin(index),
          }"
          :title="capitalizeStageName(stage.name)"
          :groups="stage.groups"
          :stage-connector-class="stageConnectorClass(index, stage)"
          :is-first-column="isFirstColumn(index)"
          :action="stage.status.action"
          @refreshPipelineGraph="refreshPipelineGraph"
        />
      </ul>
    </div>
  </div>
</template>
