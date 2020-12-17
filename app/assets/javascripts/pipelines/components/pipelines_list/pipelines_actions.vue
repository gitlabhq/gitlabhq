<script>
import { GlTooltipDirective, GlButton, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { deprecatedCreateFlash as flash } from '~/flash';
import { s__, __, sprintf } from '~/locale';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import eventHub from '../../event_hub';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlCountdown,
    GlButton,
    GlLoadingIcon,
  },
  props: {
    actions: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    onClickAction(action) {
      if (action.scheduled_at) {
        const confirmationMessage = sprintf(
          s__(
            'DelayedJobs|Are you sure you want to run %{jobName} immediately? Otherwise this job will run automatically after its timer finishes.',
          ),
          { jobName: action.name },
        );
        // https://gitlab.com/gitlab-org/gitlab-foss/issues/52156
        // eslint-disable-next-line no-alert
        if (!window.confirm(confirmationMessage)) {
          return;
        }
      }

      this.isLoading = true;

      /**
       * Ideally, the component would not make an api call directly.
       * However, in order to use the eventhub and know when to
       * toggle back the `isLoading` property we'd need an ID
       * to track the request with a wacther - since this component
       * is rendered at least 20 times in the same page, moving the
       * api call directly here is the most performant solution
       */
      axios
        .post(`${action.path}.json`)
        .then(() => {
          this.isLoading = false;
          eventHub.$emit('updateTable');
        })
        .catch(() => {
          this.isLoading = false;
          flash(__('An error occurred while making the request.'));
        });
    },

    isActionDisabled(action) {
      if (action.playable === undefined) {
        return false;
      }

      return !action.playable;
    },
  },
};
</script>
<template>
  <div class="btn-group">
    <button
      v-gl-tooltip
      type="button"
      :disabled="isLoading"
      class="dropdown-new btn btn-default js-pipeline-dropdown-manual-actions"
      :title="__('Run manual or delayed jobs')"
      data-toggle="dropdown"
      :aria-label="__('Run manual or delayed jobs')"
    >
      <gl-icon name="play" class="icon-play" />
      <gl-icon name="chevron-down" />
      <gl-loading-icon v-if="isLoading" />
    </button>

    <ul class="dropdown-menu dropdown-menu-right">
      <li v-for="action in actions" :key="action.path">
        <gl-button
          category="tertiary"
          :class="{ disabled: isActionDisabled(action) }"
          :disabled="isActionDisabled(action)"
          class="js-pipeline-action-link"
          @click="onClickAction(action)"
        >
          <div class="d-flex justify-content-between flex-wrap">
            {{ action.name }}
            <span v-if="action.scheduled_at">
              <gl-icon name="clock" />
              <gl-countdown :end-date-string="action.scheduled_at" />
            </span>
          </div>
        </gl-button>
      </li>
    </ul>
  </div>
</template>
