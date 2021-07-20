<script>
import { GlTooltipDirective, GlButton, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { dasherize } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import { reportToSentry } from '../../utils';

/**
 * Renders either a cancel, retry or play icon button and handles the post request
 *
 * Used in:
 * - mr widget mini pipeline graph: `mr_widget_pipeline.vue`
 * - pipelines table
 * - pipelines table in merge request page
 * - pipelines table in commit page
 * - pipelines detail page in big graph
 */
export default {
  components: {
    GlIcon,
    GlButton,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tooltipText: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: true,
    },
    actionIcon: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isDisabled: false,
      isLoading: false,
    };
  },
  computed: {
    cssClass() {
      const actionIconDash = dasherize(this.actionIcon);
      return `${actionIconDash} js-icon-${actionIconDash}`;
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry('action_component', `error: ${err}, info: ${info}`);
  },
  methods: {
    /**
     * The request should not be handled here.
     * However due to this component being used in several
     * different apps it avoids repetition & complexity.
     *
     */
    onClickAction() {
      this.$root.$emit(BV_HIDE_TOOLTIP, `js-ci-action-${this.link}`);
      this.isDisabled = true;
      this.isLoading = true;

      axios
        .post(`${this.link}.json`)
        .then(() => {
          this.isDisabled = false;
          this.isLoading = false;

          this.$emit('pipelineActionRequestComplete');
        })
        .catch((err) => {
          this.isDisabled = false;
          this.isLoading = false;

          reportToSentry('action_component', err);

          createFlash({
            message: __('An error occurred while making the request.'),
          });
        });
    },
  },
};
</script>
<template>
  <gl-button
    :id="`js-ci-action-${link}`"
    v-gl-tooltip="{ boundary: 'viewport' }"
    :title="tooltipText"
    :class="cssClass"
    :disabled="isDisabled"
    class="js-ci-action gl-ci-action-icon-container ci-action-icon-container ci-action-icon-wrapper gl-display-flex gl-align-items-center gl-justify-content-center"
    @click.stop="onClickAction"
  >
    <gl-loading-icon v-if="isLoading" size="sm" class="js-action-icon-loading" />
    <gl-icon v-else :name="actionIcon" class="gl-mr-0!" :aria-label="actionIcon" />
  </gl-button>
</template>
