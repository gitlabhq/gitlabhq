<script>
import { GlTab, GlLoadingIcon, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import ActivityCalendar from './activity_calendar.vue';

export default {
  i18n: {
    title: s__('UserProfile|Overview'),
    personalProjects: s__('UserProfile|Personal projects'),
    viewAll: s__('UserProfile|View all'),
  },
  components: { GlTab, GlLoadingIcon, GlLink, ActivityCalendar, ProjectsList },
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
};
</script>

<template>
  <gl-tab :title="$options.i18n.title">
    <activity-calendar />
    <div class="gl-mx-n3 gl-display-flex gl-flex-wrap">
      <div class="gl-px-3 gl-w-full gl-lg-w-half"></div>
      <div class="gl-px-3 gl-w-full gl-lg-w-half" data-testid="personal-projects-section">
        <div
          class="gl-display-flex gl-align-items-center gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid"
        >
          <h4 class="gl-flex-grow-1">{{ $options.i18n.personalProjects }}</h4>
          <gl-link href="">{{ $options.i18n.viewAll }}</gl-link>
        </div>
        <gl-loading-icon v-if="personalProjectsLoading" class="gl-mt-5" size="md" />
        <projects-list v-else :projects="personalProjects" />
      </div>
    </div>
  </gl-tab>
</template>
