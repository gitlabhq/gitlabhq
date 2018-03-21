import Vue from 'vue';
import PipelinesStore from '../../../../pipelines/stores/pipelines_store';
import pipelinesComponent from '../../../../pipelines/components/pipelines.vue';
import Translate from '../../../../vue_shared/translate';
import { convertPermissionToBoolean } from '../../../../lib/utils/common_utils';

Vue.use(Translate);

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#pipelines-list-vue',
  components: {
    pipelinesComponent,
  },
  data() {
    return {
      store: new PipelinesStore(),
    };
  },
  created() {
    this.dataset = document.querySelector(this.$options.el).dataset;
  },
  render(createElement) {
    return createElement('pipelines-component', {
      props: {
        store: this.store,
        endpoint: this.dataset.endpoint,
        helpPagePath: this.dataset.helpPagePath,
        emptyStateSvgPath: this.dataset.emptyStateSvgPath,
        errorStateSvgPath: this.dataset.errorStateSvgPath,
        noPipelinesSvgPath: this.dataset.noPipelinesSvgPath,
        autoDevopsPath: this.dataset.helpAutoDevopsPath,
        newPipelinePath: this.dataset.newPipelinePath,
        canCreatePipeline: convertPermissionToBoolean(this.dataset.canCreatePipeline),
        hasGitlabCi: convertPermissionToBoolean(this.dataset.hasGitlabCi),
        ciLintPath: this.dataset.ciLintPath,
        resetCachePath: this.dataset.resetCachePath,
      },
    });
  },
}));
