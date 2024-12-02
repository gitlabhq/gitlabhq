<script>
import { GlTab, GlLoadingIcon, GlLink } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import ActivityCalendar from './activity_calendar.vue';

export default {
  i18n: {
    title: s__('UserProfile|Overview'),
    personalProjects: s__('UserProfile|Personal projects'),
    activity: s__('UserProfile|Activity'),
    viewAll: s__('UserProfile|View all'),
    eventsErrorMessage: s__(
      'UserProfile|An error occurred loading the activity. Please refresh the page to try again.',
    ),
  },
  components: { GlTab, GlLoadingIcon, GlLink, ActivityCalendar, ProjectsList, ContributionEvents },
  inject: ['userActivityPath'],
  props: {
    personalProjects: {
      type: Array,
      required: true,
    },
    personalProjectsLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      events: [],
      eventsLoading: false,
    };
  },
  async mounted() {
    this.eventsLoading = true;

    try {
      const { data: events } = await axios.get(this.userActivityPath, {
        params: { limit: 10 },
      });
      this.events = events;
    } catch (error) {
      createAlert({ message: this.$options.i18n.eventsErrorMessage, error, captureError: true });
    } finally {
      this.eventsLoading = false;
    }
  },
};
</script>

<template>
  <gl-tab :title="$options.i18n.title">
    <div class="gl-mt-5 gl-flex gl-flex-wrap">
      <div class="gl-w-full" data-testid="activity-section">
        <div class="gl-flex gl-items-center gl-border-b-1 gl-border-b-default gl-border-b-solid">
          <h4 class="gl-grow">{{ $options.i18n.activity }}</h4>
          <gl-link href="">{{ $options.i18n.viewAll }}</gl-link>
        </div>
        <activity-calendar />
        <gl-loading-icon v-if="eventsLoading" class="gl-mt-5" size="md" />
        <contribution-events v-else :events="events" />
      </div>
      <div class="gl-w-full" data-testid="personal-projects-section">
        <div class="gl-flex gl-items-center gl-border-b-1 gl-border-b-default gl-border-b-solid">
          <h4 class="gl-grow">{{ $options.i18n.personalProjects }}</h4>
          <gl-link href="">{{ $options.i18n.viewAll }}</gl-link>
        </div>
        <gl-loading-icon v-if="personalProjectsLoading" class="gl-mt-5" size="md" />
        <projects-list v-else :projects="personalProjects" />
      </div>
    </div>
  </gl-tab>
</template>
