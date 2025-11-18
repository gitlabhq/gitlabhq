<script>
import { GlButton, GlCollapse, GlIcon } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'RefTrackingSelectionSummary',
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
  },
  props: {
    selectedRefs: {
      type: Array,
      required: true,
    },
    availableSpots: {
      type: Number,
      required: true,
    },
  },
  computed: {
    selectedRefsCount() {
      return this.selectedRefs.length;
    },
    hasSelectedRefs() {
      return this.selectedRefs.length > 0;
    },
  },
  methods: {
    getRefIcon(refType) {
      return refType === 'BRANCH' ? 'branch' : 'tag';
    },
    getRemoveAriaLabel(refName) {
      return sprintf(s__('SecurityTrackedRefs|Remove %{refName}'), { refName });
    },
  },
};
</script>

<template>
  <div class="gl-rounded-base gl-border-1 gl-border-solid gl-border-blue-500 gl-bg-blue-50">
    <!-- We are using tabular numbers (stably width) to prevent layout shifts when the number of selected refs changes -->
    <div class="gl-px-4 gl-py-3 gl-tabular-nums gl-text-blue-600">
      {{
        sprintf(
          s__(
            'SecurityTrackedRefs|%{selectedRefsCount} refs selected of %{availableSpots} spots available',
          ),
          { selectedRefsCount, availableSpots },
        )
      }}

      <gl-collapse :visible="availableSpots <= 0" data-testid="max-limit-warning-container">
        <div data-testid="max-limit-warning" class="gl-text-sm">
          {{ s__('SecurityTrackedRefs|You can remove tracked refs in the Configuration page.') }}
        </div>
      </gl-collapse>
    </div>

    <gl-collapse :visible="hasSelectedRefs" data-testid="selected-refs-chips">
      <div class="gl-mt-1 gl-px-4 gl-pb-3">
        <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
          <span
            v-for="ref in selectedRefs"
            :key="ref.id"
            class="gl-inline-flex gl-items-center gl-gap-2 gl-rounded-base gl-bg-gray-100 gl-px-3 gl-py-2 gl-text-sm gl-text-gray-700"
            data-testid="selected-ref-chip"
          >
            <gl-icon :name="getRefIcon(ref.refType)" :size="12" />
            <span class="gl-font-semibold">{{ ref.name }}</span>
            <gl-button
              category="tertiary"
              size="small"
              icon="close"
              :aria-label="getRemoveAriaLabel(ref.name)"
              @click="$emit('remove', ref)"
            />
          </span>
        </div>
      </div>
    </gl-collapse>
  </div>
</template>
