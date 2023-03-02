<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { debounce } from 'lodash';

import { __ } from '~/locale';
import AjaxCache from '~/lib/utils/ajax_cache';
import ActivityCalendar from '~/pages/users/activity_calendar';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
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
      showCalendar: true,
      hasError: false,
    };
  },
  mounted() {
    this.renderActivityCalendar();
    window.addEventListener('resize', this.handleResize);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleResize);
  },
  methods: {
    async renderActivityCalendar() {
      if (bp.getBreakpointSize() === 'xs') {
        this.showCalendar = false;

        return;
      }

      this.showCalendar = true;
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
    handleResize: debounce(function debouncedHandleResize() {
      this.renderActivityCalendar();
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    handleClickDay() {
      // Render activities for specific day.
      // Blocked by https://gitlab.com/gitlab-org/gitlab/-/issues/378695
    },
  },
};
</script>

<template>
  <div v-if="showCalendar" ref="calendarContainer">
    <gl-loading-icon v-if="isLoading" size="md" />
    <gl-alert
      v-else-if="hasError"
      :title="$options.i18n.errorAlertTitle"
      :dismissible="false"
      variant="danger"
      :primary-button-text="$options.i18n.retry"
      @primaryAction="renderActivityCalendar"
    />
    <div v-else class="gl-text-center">
      <div class="gl-display-inline-block gl-relative">
        <div ref="calendarSvgContainer"></div>
        <p class="gl-absolute gl-right-0 gl-bottom-0 gl-mb-0 gl-font-sm">
          {{ $options.i18n.calendarHint }}
        </p>
      </div>
    </div>
  </div>
</template>
