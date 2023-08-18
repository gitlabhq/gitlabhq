<script>
import { GlCard } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { formatTraceDuration } from './trace_utils';

const CARD_CLASS = 'gl-mr-7 gl-w-15p gl-min-w-fit-content';
const HEADER_CLASS =
  'gl-p-2 gl-font-weight-bold gl-display-flex gl-justify-content-center gl-align-items-center';
const BODY_CLASS =
  'gl--flex-center gl-flex-direction-column gl-my-0 gl-p-4 gl-font-weight-bold gl-text-center gl-flex-grow-1 gl-font-lg';

export default {
  CARD_CLASS,
  HEADER_CLASS,
  BODY_CLASS,
  components: {
    GlCard,
  },
  props: {
    trace: {
      required: true,
      type: Object,
    },
  },
  computed: {
    title() {
      return `${this.trace.service_name} : ${this.trace.operation}`;
    },
    traceDate() {
      return formatDate(this.trace.timestamp, 'mmm d, yyyy');
    },
    traceTime() {
      return formatDate(this.trace.timestamp, 'H:MM:ss Z');
    },
    traceDuration() {
      return formatTraceDuration(this.trace.duration_nano);
    },
  },
};
</script>

<template>
  <div class="gl-mb-6">
    <h1>{{ title }}</h1>

    <div class="gl-display-flex gl-flex-wrap gl-justify-content-center gl-my-7 gl-row-gap-6">
      <gl-card
        data-testid="trace-date-card"
        :class="$options.CARD_CLASS"
        :body-class="$options.BODY_CLASS"
        :header-class="$options.HEADER_CLASS"
      >
        <template #header>
          {{ __('Trace Start') }}
        </template>

        <template #default>
          <span>{{ traceDate }}</span>
          <span class="gl-text-secondary gl-font-weight-normal">{{ traceTime }}</span>
        </template>
      </gl-card>

      <gl-card
        data-testid="trace-duration-card"
        :class="$options.CARD_CLASS"
        :body-class="$options.BODY_CLASS"
        :header-class="$options.HEADER_CLASS"
      >
        <template #header>
          {{ __('Duration') }}
        </template>

        <template #default>
          <span>{{ traceDuration }}</span>
        </template>
      </gl-card>

      <gl-card
        data-testid="trace-spans-card"
        :class="$options.CARD_CLASS"
        :body-class="$options.BODY_CLASS"
        :header-class="$options.HEADER_CLASS"
      >
        <template #header>
          {{ __('Total Spans') }}
        </template>

        <template #default>
          <span>{{ trace.totalSpans }}</span>
        </template>
      </gl-card>
    </div>
  </div>
</template>
