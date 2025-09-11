<script>
import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'PickUpWidget',
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
  },
  props: {
    lastPushEvent: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      dismissed: false,
    };
  },
  computed: {
    branchName() {
      return this.lastPushEvent.ref_name || this.lastPushEvent.branch_name || '';
    },
    projectName() {
      return this.lastPushEvent?.project?.name || '';
    },
    projectPath() {
      return this.lastPushEvent?.project?.web_url || '';
    },
    createdAt() {
      return this.lastPushEvent?.created_at;
    },
    createMrPath() {
      return this.lastPushEvent?.create_mr_path || '';
    },
  },
  methods: {
    dismissAlert() {
      this.dismissed = true;
    },
  },
};
</script>

<template>
  <div v-if="!dismissed" data-testid="pick-up-widget-container">
    <h2 class="gl-heading-4 gl-mb-4 gl-mt-0">{{ __('Pick up where you left off') }}</h2>
    <div class="gl-border gl-mt-3 gl-rounded-lg gl-border-default gl-p-4">
      <div class="gl-flex-col gl-space-y-2">
        <div class="gl-flex gl-justify-between">
          <gl-link
            v-if="projectPath"
            :href="projectPath"
            class="gl-font-semibold gl-text-default"
            data-testid="project-link"
          >
            {{ projectName }}
          </gl-link>
          <time-ago-tooltip
            v-if="createdAt"
            :time="createdAt"
            class="gl-text-sm gl-text-subtle"
            data-testid="time-ago"
          />
        </div>

        <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
          <gl-sprintf
            :message="
              __('You published branch %{branchName}. Take the next step when you are ready.')
            "
          >
            <template #branchName>
              <code>{{ branchName }}</code>
            </template>
          </gl-sprintf>
        </div>
        <div class="gl-flex gl-space-x-2 gl-pt-3">
          <gl-button
            v-if="createMrPath"
            :href="lastPushEvent.create_mr_path"
            variant="confirm"
            size="small"
            data-testid="create-merge-request-button"
          >
            {{ __('Create merge request') }}
          </gl-button>
          <gl-button
            variant="default"
            size="small"
            data-testid="dismiss-button"
            @click="dismissAlert"
          >
            {{ __('Dismiss') }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
