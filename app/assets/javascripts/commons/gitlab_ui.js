import Vue from 'vue';
import {
  Pagination,
  ProgressBar,
  Modal,
  LoadingIcon,
  ModalDirective,
  TooltipDirective,
} from '@gitlab-org/gitlab-ui';

Vue.component('gl-pagination', Pagination);
Vue.component('gl-progress-bar', ProgressBar);
Vue.component('gl-ui-modal', Modal);
Vue.component('gl-loading-icon', LoadingIcon);

Vue.directive('gl-modal', ModalDirective);
Vue.directive('gl-tooltip', TooltipDirective);
