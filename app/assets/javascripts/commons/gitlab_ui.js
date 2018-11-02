import Vue from 'vue';
import { GlLoadingIcon, GlTooltipDirective } from '@gitlab-org/gitlab-ui';

Vue.component('gl-loading-icon', GlLoadingIcon);

Vue.directive('gl-tooltip', GlTooltipDirective);
