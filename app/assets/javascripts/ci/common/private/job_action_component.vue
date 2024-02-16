<script>
import { GlTooltipDirective, GlButton, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { dasherize } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import { reportToSentry } from '~/ci/utils';

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
    withConfirmationModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    shouldTriggerClick: {
      type: Boolean,
      required: false,
      default: false,
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
  watch: {
    shouldTriggerClick(flag) {
      if (flag && this.withConfirmationModal) {
        this.executeAction();
        this.$emit('actionButtonClicked');
      }
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
    onClickAction(e) {
      e.preventDefault();

      if (this.withConfirmationModal) {
        this.$emit('showActionConfirmationModal');
      } else {
        this.executeAction();
      }
    },
    executeAction() {
      this.$root.$emit(BV_HIDE_TOOLTIP, `js-ci-action-${this.link}`);
      this.isDisabled = true;
      this.isLoading = true;

      axios
        .post(`${this.link}.json`)
        .then(() => {
          this.isLoading = false;

          this.$emit('pipelineActionRequestComplete');
        })
        .catch((err) => {
          this.isDisabled = false;
          this.isLoading = false;

          reportToSentry('action_component', err);

          createAlert({
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
    ref="button"
    :class="cssClass"
    :disabled="isDisabled"
    size="small"
    class="js-ci-action gl-ci-action-icon-container ci-action-icon-container ci-action-icon-wrapper gl-display-flex gl-align-items-center gl-justify-content-center"
    data-testid="ci-action-button"
    @click.stop="onClickAction"
  >
    <div
      v-gl-tooltip.viewport
      :title="tooltipText"
      class="gl-display-flex gl-align-items-center gl-justify-content-center gl-h-full"
      data-testid="ci-action-icon-tooltip-wrapper"
    >
      <gl-loading-icon
        v-if="isLoading"
        size="sm"
        class="gl-button-icon gl-m-2 js-action-icon-loading"
      />
      <gl-icon
        v-else
        :name="actionIcon"
        class="gl-button-icon gl-p-1 gl-mr-0!"
        :aria-label="actionIcon"
      />
    </div>
  </gl-button>
</template>
