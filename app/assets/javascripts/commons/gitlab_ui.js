import Vue from 'vue';
import { GlProgressBar, GlLoadingIcon, GlTooltipDirective } from '@gitlab-org/gitlab-ui';

Vue.component('gl-progress-bar', GlProgressBar);
Vue.component('gl-loading-icon', GlLoadingIcon);

Vue.directive('gl-tooltip', GlTooltipDirective);
