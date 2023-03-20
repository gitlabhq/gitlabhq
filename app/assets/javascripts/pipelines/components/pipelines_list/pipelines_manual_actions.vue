<script>
import { GlDropdown, GlDropdownItem, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { s__, __, sprintf } from '~/locale';
import Tracking from '~/tracking';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import eventHub from '../../event_hub';
import { TRACKING_CATEGORIES } from '../../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlCountdown,
    GlDropdown,
    GlDropdownItem,
    GlIcon,
  },
  mixins: [Tracking.mixin()],
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
    async onClickAction(action) {
      if (action.scheduled_at) {
        const confirmationMessage = sprintf(
          s__(
            'DelayedJobs|Are you sure you want to run %{jobName} immediately? Otherwise this job will run automatically after its timer finishes.',
          ),
          { jobName: action.name },
        );

        const confirmed = await confirmAction(confirmationMessage);

        if (!confirmed) {
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
          createAlert({ message: __('An error occurred while making the request.') });
        });
    },
    isActionDisabled(action) {
      if (action.playable === undefined) {
        return false;
      }

      return !action.playable;
    },
    trackClick() {
      this.track('click_manual_actions', { label: TRACKING_CATEGORIES.table });
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-gl-tooltip
    :title="__('Run manual or delayed jobs')"
    :loading="isLoading"
    data-testid="pipelines-manual-actions-dropdown"
    right
    lazy
    icon="play"
    @shown="trackClick"
  >
    <gl-dropdown-item
      v-for="action in actions"
      :key="action.path"
      :disabled="isActionDisabled(action)"
      @click="onClickAction(action)"
    >
      <div class="gl-display-flex gl-justify-content-space-between gl-flex-wrap">
        {{ action.name }}
        <span v-if="action.scheduled_at">
          <gl-icon name="clock" />
          <gl-countdown :end-date-string="action.scheduled_at" />
        </span>
      </div>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
