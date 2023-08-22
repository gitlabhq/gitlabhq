<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { __ } from '~/locale';
import { TYPE_ISSUE, WORKSPACE_PROJECT } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

export default {
  TYPE_ISSUE,
  WORKSPACE_PROJECT,
  components: {
    GlIcon,
    ConfidentialityBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['hidden'],
  computed: {
    ...mapGetters(['getNoteableData']),
    isLocked() {
      return this.getNoteableData.discussion_locked;
    },
    isConfidential() {
      return this.getNoteableData.confidential;
    },
    warningIconsMeta() {
      return [
        {
          iconName: 'lock',
          visible: this.isLocked,
          dataTestId: 'locked',
          tooltip: __('This merge request is locked. Only project members can comment.'),
        },
        {
          iconName: 'spam',
          visible: this.hidden,
          dataTestId: 'hidden',
          tooltip: __('This merge request is hidden because its author has been banned'),
        },
      ];
    },
  },
};
</script>

<template>
  <div class="gl-display-inline-block">
    <confidentiality-badge
      v-if="isConfidential"
      class="gl-mr-3"
      :issuable-type="$options.TYPE_ISSUE"
      :workspace-type="$options.WORKSPACE_PROJECT"
    />
    <template v-for="meta in warningIconsMeta">
      <div
        v-if="meta.visible"
        :key="meta.iconName"
        v-gl-tooltip.bottom
        :data-testid="meta.dataTestId"
        :title="meta.tooltip || null"
        class="issuable-warning-icon gl-mr-3 gl-mt-2 gl-display-flex gl-justify-content-center gl-align-items-center"
      >
        <gl-icon :name="meta.iconName" class="icon" />
      </div>
    </template>
  </div>
</template>
