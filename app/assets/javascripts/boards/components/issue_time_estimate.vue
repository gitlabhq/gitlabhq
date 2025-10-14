<script>
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import { sprintf, __ } from '~/locale';

export default {
  i18n: {
    timeEstimate: __('Time estimate'),
  },
  components: {
    WorkItemAttribute,
  },
  inject: ['timeTrackingLimitToHours'],
  props: {
    estimate: {
      type: Number,
      required: true,
    },
  },
  computed: {
    title() {
      return stringifyTime(
        parseSeconds(this.estimate, { limitToHours: this.timeTrackingLimitToHours }),
        true,
      );
    },
    timeEstimate() {
      return stringifyTime(
        parseSeconds(this.estimate, { limitToHours: this.timeTrackingLimitToHours }),
      );
    },
  },
  methods: {
    createAriaLabel() {
      return sprintf(__(`Time estimate: %{estimate}`), {
        estimate: this.title,
      });
    },
  },
};
</script>

<template>
  <work-item-attribute
    wrapper-component="button"
    anchor-id="board-card-time-estimate"
    wrapper-component-class="board-card-info board-card-weight gl-inline-flex gl-cursor-help gl-items-center gl-align-bottom gl-text-sm gl-text-subtle !gl-cursor-help gl-bg-transparent gl-border-0 gl-p-0 focus-visible:gl-focus-inset"
    title-component-class="board-card-info-text"
    icon-name="hourglass"
    icon-class="gl-mr-1"
    :aria-label="createAriaLabel()"
  >
    <template #title>
      <span class="board-card-info gl-cursor-help gl-text-subtle">
        <time class="board-card-info-text gl-text-sm">{{ timeEstimate }}</time>
      </span>
    </template>
    <template #tooltip-text>
      <span data-testid="issue-time-estimate">
        <span class="gl-block gl-font-bold">{{ $options.i18n.timeEstimate }}</span>
        <span>{{ title }}</span>
      </span>
    </template>
  </work-item-attribute>
</template>
