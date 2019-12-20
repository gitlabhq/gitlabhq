<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import MRWidgetService from '../../services/mr_widget_service';

export default {
  name: 'DeploymentStopButton',
  components: {
    LoadingButton,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isDeployInProgress: {
      type: Boolean,
      required: true,
    },
    stopUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isStopping: false,
    };
  },
  computed: {
    deployInProgressTooltip() {
      return this.isDeployInProgress
        ? __('Stopping this environment is currently not possible as a deployment is in progress')
        : '';
    },
  },
  methods: {
    stopEnvironment() {
      const msg = __('Are you sure you want to stop this environment?');
      const isConfirmed = confirm(msg); // eslint-disable-line

      if (isConfirmed) {
        this.isStopping = true;

        MRWidgetService.stopEnvironment(this.stopUrl)
          .then(res => res.data)
          .then(data => {
            if (data.redirect_url) {
              visitUrl(data.redirect_url);
            }

            this.isStopping = false;
          })
          .catch(() => {
            createFlash(
              __('Something went wrong while stopping this environment. Please try again.'),
            );
            this.isStopping = false;
          });
      }
    },
  },
};
</script>

<template>
  <span v-gl-tooltip :title="deployInProgressTooltip" class="d-inline-block" tabindex="0">
    <loading-button
      v-gl-tooltip
      :loading="isStopping"
      :disabled="isDeployInProgress"
      :title="__('Stop environment')"
      container-class="js-stop-env btn btn-default btn-sm inline prepend-left-4"
      @click="stopEnvironment"
    >
      <icon name="stop" />
    </loading-button>
  </span>
</template>
