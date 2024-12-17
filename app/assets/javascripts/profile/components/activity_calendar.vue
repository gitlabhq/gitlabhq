<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import AjaxCache from '~/lib/utils/ajax_cache';
import ActivityCalendar from '~/pages/users/activity_calendar';
import { getVisibleCalendarPeriod } from '../utils';

export default {
  i18n: {
    errorAlertTitle: __('There was an error loading users activity calendar.'),
    retry: __('Retry'),
    calendarHint: __('Issues, merge requests, pushes, and comments.'),
  },
  components: { GlLoadingIcon, GlAlert },
  inject: ['userCalendarPath', 'utcOffset'],
  data() {
    return {
      isLoading: true,
      hasError: false,
    };
  },
  mounted() {
    this.renderActivityCalendar();
  },
  methods: {
    async renderActivityCalendar() {
      this.isLoading = true;
      this.hasError = false;

      try {
        const data = await AjaxCache.retrieve(this.userCalendarPath);

        this.isLoading = false;

        // Wait for `calendarContainer` to render
        await this.$nextTick();
        const monthsAgo = getVisibleCalendarPeriod(this.$refs.calendarContainer);

        // eslint-disable-next-line no-new
        new ActivityCalendar({
          container: this.$refs.calendarSvgContainer,
          timestamps: data,
          utcOffset: this.utcOffset,
          firstDayOfWeek: gon.first_day_of_week,
          monthsAgo,
          onClickDay: this.handleClickDay,
        });
      } catch {
        this.isLoading = false;
        this.hasError = true;
      }
    },
    handleClickDay() {
      // Render activities for specific day.
      // Blocked by https://gitlab.com/gitlab-org/gitlab/-/issues/378695
    },
  },
};
</script>

<template>
  <div ref="calendarContainer" class="gl-border-b gl-pb-5">
    <gl-loading-icon v-if="isLoading" size="sm" />
    <gl-alert
      v-else-if="hasError"
      :title="$options.i18n.errorAlertTitle"
      :dismissible="false"
      variant="danger"
      :primary-button-text="$options.i18n.retry"
      @primaryAction="renderActivityCalendar"
    />
    <div v-else class="gl-relative gl-inline-block gl-w-full">
      <div ref="calendarSvgContainer"></div>
      <p class="gl-absolute gl-bottom-0 gl-right-0 gl-mb-0 gl-text-sm gl-text-subtle">
        {{ $options.i18n.calendarHint }}
      </p>
    </div>
  </div>
</template>
