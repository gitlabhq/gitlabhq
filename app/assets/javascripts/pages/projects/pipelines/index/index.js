import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { doesHashExistInUrl } from '~/lib/utils/url_utility';
import {
  parseBoolean,
  historyReplaceState,
  buildUrlWithCurrentLocation,
} from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import PipelinesStore from '../../../../pipelines/stores/pipelines_store';
import pipelinesComponent from '../../../../pipelines/components/pipelines.vue';
import Translate from '../../../../vue_shared/translate';

Vue.use(Translate);
Vue.use(GlToast);

document.addEventListener(
  'DOMContentLoaded',
  () =>
    new Vue({
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

        if (doesHashExistInUrl('delete_success')) {
          this.$toast.show(__('The pipeline has been deleted'));
          historyReplaceState(buildUrlWithCurrentLocation());
        }
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
            canCreatePipeline: parseBoolean(this.dataset.canCreatePipeline),
            hasGitlabCi: parseBoolean(this.dataset.hasGitlabCi),
            ciLintPath: this.dataset.ciLintPath,
            resetCachePath: this.dataset.resetCachePath,
          },
        });
      },
    }),
);
