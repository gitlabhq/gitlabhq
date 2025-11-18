<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import RefTrackingMetadata from './ref_tracking_metadata.vue';

export default {
  name: 'RefTrackingListItem',
  components: {
    GlDisclosureDropdown,
    RefTrackingMetadata,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    trackedRef: {
      type: Object,
      required: true,
    },
  },
  computed: {
    untrackAction() {
      return [
        {
          text: s__('SecurityTrackedRefs|Remove ref tracking'),
          action: () => this.handleUntrack(),
          variant: 'danger',
        },
      ];
    },
  },
  methods: {
    handleUntrack() {
      this.$emit('untrack', this.trackedRef);
    },
  },
};
</script>

<template>
  <li class="gl-border-b gl-px-4 gl-py-4 last:gl-border-b-0">
    <div class="gl-flex gl-items-start gl-justify-between">
      <div class="gl-flex-1">
        <ref-tracking-metadata :tracked-ref="trackedRef" />
      </div>

      <div class="gl-ml-3 gl-flex gl-shrink-0 gl-items-center gl-gap-3">
        <span class="gl-text-sm" data-testid="vulnerabilities-count"
          >{{ trackedRef.vulnerabilitiesCount }}
          {{
            n__(
              'SecurityTrackedRefs|open vulnerability',
              'SecurityTrackedRefs|open vulnerabilities',
              trackedRef.vulnerabilitiesCount,
            )
          }}
        </span>
        <gl-disclosure-dropdown
          v-gl-tooltip="
            trackedRef.isDefault
              ? s__('SecurityTrackedRefs|The default ref cannot be removed from being tracked')
              : ''
          "
          :items="untrackAction"
          icon="ellipsis_v"
          no-caret
          category="tertiary"
          :toggle-text="__('Actions')"
          text-sr-only
          placement="bottom-end"
          data-testid="ref-actions-dropdown"
          :disabled="trackedRef.isDefault"
        />
      </div>
    </div>
  </li>
</template>
