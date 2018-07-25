<script>
import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { dasherize } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import createFlash from '~/flash';
import tooltip from '~/vue_shared/directives/tooltip';
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
  },

  directives: {
    tooltip,
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
      $(this.$el).tooltip('hide');

      this.isDisabled = true;

      axios
        .post(`${this.link}.json`)
        .then(() => {
          this.isDisabled = false;
          this.$emit('pipelineActionRequestComplete');
        })
        .catch(() => {
          this.isDisabled = false;

          createFlash(__('An error occurred while making the request.'));
        });
    },
  },
};
</script>
<template>
  <button
    v-tooltip
    :title="tooltipText"
    :class="cssClass"
    :disabled="isDisabled"
    type="button"
    class="js-ci-action btn btn-blank
btn-transparent ci-action-icon-container ci-action-icon-wrapper"
    data-container="body"
    data-boundary="viewport"
    @click="onClickAction"
  >
    <icon :name="actionIcon"/>
  </button>
</template>
