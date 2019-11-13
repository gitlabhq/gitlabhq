<script>
import { GlTooltipDirective, GlButton, GlLoadingIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { dasherize } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import createFlash from '~/flash';
import Icon from '~/vue_shared/components/icon.vue';

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
    Icon,
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
  methods: {
    /**
     * The request should not be handled here.
     * However due to this component being used in several
     * different apps it avoids repetition & complexity.
     *
     */
    onClickAction() {
      this.$root.$emit('bv::hide::tooltip', `js-ci-action-${this.link}`);
      this.isDisabled = true;
      this.isLoading = true;

      axios
        .post(`${this.link}.json`)
        .then(() => {
          this.isDisabled = false;
          this.isLoading = false;

          this.$emit('pipelineActionRequestComplete');
        })
        .catch(() => {
          this.isDisabled = false;
          this.isLoading = false;

          createFlash(__('An error occurred while making the request.'));
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
    class="js-ci-action btn btn-blank btn-transparent ci-action-icon-container ci-action-icon-wrapper d-flex align-items-center justify-content-center"
    @click="onClickAction"
  >
    <gl-loading-icon v-if="isLoading" class="js-action-icon-loading" />
    <icon v-else :name="actionIcon" />
  </gl-button>
</template>
