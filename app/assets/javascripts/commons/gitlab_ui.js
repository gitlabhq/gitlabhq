import Vue from 'vue';
import {
  GlPagination,
  GlProgressBar,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab-org/gitlab-ui';

Vue.component('gl-pagination', GlPagination);
Vue.component('gl-progress-bar', GlProgressBar);
Vue.component('gl-loading-icon', GlLoadingIcon);

Vue.directive('gl-tooltip', GlTooltipDirective);
