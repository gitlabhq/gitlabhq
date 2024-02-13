<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlIcon,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { s__, __, sprintf } from '~/locale';
import Tracking from '~/tracking';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';
import { TRACKING_CATEGORIES } from '../../constants';
import getPipelineActionsQuery from '../graphql/queries/get_pipeline_actions.query.graphql';

export default {
  name: 'PipelinesManualActions',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlCountdown,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlIcon,
    GlLoadingIcon,
  },
  mixins: [Tracking.mixin()],
  inject: ['fullPath', 'manualActionsLimit'],
  props: {
    iid: {
      type: Number,
      required: true,
    },
  },
  apollo: {
    actions: {
      query: getPipelineActionsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
          limit: this.manualActionsLimit,
        };
      },
      skip() {
        return !this.hasDropdownBeenShown;
      },
      update({ project }) {
        return project?.pipeline?.jobs?.nodes || [];
      },
    },
  },
  data() {
    return {
      isLoading: false,
      actions: [],
      hasDropdownBeenShown: false,
      isDropdownVisible: false,
    };
  },
  computed: {
    isActionsLoading() {
      return this.$apollo.queries.actions.loading;
    },
    isDropdownLimitReached() {
      return this.actions.length === this.manualActionsLimit;
    },
  },
  methods: {
    async onClickAction(action) {
      if (action.scheduledAt) {
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
       * to track the request with a watcher - since this component
       * is rendered at least 20 times in the same page, moving the
       * api call directly here is the most performant solution
       */
      axios
        .post(`${action.playPath}.json`)
        .then(() => {
          this.isLoading = false;
          this.$emit('refresh-pipeline-table');
        })
        .catch(() => {
          this.isLoading = false;
          createAlert({ message: __('An error occurred while making the request.') });
        });
    },
    fetchActions() {
      this.isDropdownVisible = true;
      this.hasDropdownBeenShown = true;

      this.$apollo.queries.actions.refetch();

      this.trackClick();
    },
    hideAction() {
      this.isDropdownVisible = false;
    },
    trackClick() {
      this.track('click_manual_actions', { label: TRACKING_CATEGORIES.table });
    },
    jobItem(job) {
      return {
        text: job.name,
        extraAttrs: {
          disabled: !job.canPlayJob,
        },
      };
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip.left="isDropdownVisible ? '' : __('Run manual or delayed jobs')"
    :loading="isLoading"
    data-testid="pipelines-manual-actions-dropdown"
    right
    lazy
    icon="play"
    @shown="fetchActions"
    @hidden="hideAction"
  >
    <gl-disclosure-dropdown-item v-if="isActionsLoading">
      <template #list-item>
        <div class="gl-display-flex">
          <gl-loading-icon class="mr-2" />
          <span>{{ __('Loading...') }}</span>
        </div>
      </template>
    </gl-disclosure-dropdown-item>

    <gl-disclosure-dropdown-item
      v-for="action in actions"
      v-else
      :key="action.id"
      :item="jobItem(action)"
      @action="onClickAction(action)"
    >
      <template #list-item>
        <div class="gl-display-flex gl-justify-content-space-between gl-flex-wrap">
          {{ action.name }}
          <span v-if="action.scheduledAt">
            <gl-icon name="clock" />
            <gl-countdown :end-date-string="action.scheduledAt" />
          </span>
        </div>
      </template>
    </gl-disclosure-dropdown-item>

    <template #footer>
      <gl-disclosure-dropdown-item v-if="isDropdownLimitReached">
        <template #list-item>
          <span class="gl-font-sm gl-text-gray-300!" data-testid="limit-reached-msg">
            {{ __('Showing first 50 actions.') }}
          </span>
        </template>
      </gl-disclosure-dropdown-item>
    </template>
  </gl-disclosure-dropdown>
</template>
