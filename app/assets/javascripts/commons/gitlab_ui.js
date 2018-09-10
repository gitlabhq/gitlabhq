import Vue from 'vue';
import progressBar from '@gitlab-org/gitlab-ui/dist/components/base/progress_bar';
import modal from '@gitlab-org/gitlab-ui/dist/components/base/modal';

import dModal from '@gitlab-org/gitlab-ui/dist/directives/modal';
import dTooltip from '@gitlab-org/gitlab-ui/dist/directives/tooltip';

Vue.component('gl-progress-bar', progressBar);
Vue.component('gl-ui-modal', modal);

Vue.directive('gl-modal', dModal);
Vue.directive('gl-tooltip', dTooltip);
