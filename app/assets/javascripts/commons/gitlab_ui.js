import Vue from 'vue';
import {
  GlProgressBar,
  GlModal,
  GlLoadingIcon,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab-org/gitlab-ui';

Vue.component('gl-progress-bar', GlProgressBar);
Vue.component('gl-ui-modal', GlModal);
Vue.component('gl-loading-icon', GlLoadingIcon);

Vue.directive('gl-modal', GlModalDirective);
Vue.directive('gl-tooltip', GlTooltipDirective);
