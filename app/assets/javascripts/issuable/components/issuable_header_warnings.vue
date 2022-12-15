<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { __ } from '~/locale';
import { IssuableType, WorkspaceType } from '~/issues/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

export default {
  WorkspaceType,
  IssuableType,
  components: {
    GlIcon,
    ConfidentialityBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['hidden'],
  computed: {
    ...mapGetters(['getNoteableData']),
    isLocked() {
      return this.getNoteableData.discussion_locked;
    },
    isConfidential() {
      return this.getNoteableData.confidential;
    },
    isMergeRequest() {
      return this.getNoteableData.targetType === 'merge_request';
    },
    warningIconsMeta() {
      return [
        {
          iconName: 'lock',
          visible: this.isLocked,
          dataTestId: 'locked',
        },
        {
          iconName: 'spam',
          visible: this.hidden,
          dataTestId: 'hidden',
          tooltip: __('This issue is hidden because its author has been banned'),
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
      data-testid="confidential"
      :workspace-type="$options.WorkspaceType.project"
      :issuable-type="$options.IssuableType.Issue"
    />
    <template v-for="meta in warningIconsMeta">
      <div
        v-if="meta.visible"
        :key="meta.iconName"
        v-gl-tooltip
        :data-testid="meta.dataTestId"
        :title="meta.tooltip || null"
        :class="{
          'gl-mr-3 gl-mt-2 gl-display-flex gl-justify-content-center gl-align-items-center': isMergeRequest,
          'gl-display-inline-block': !isMergeRequest,
        }"
        class="issuable-warning-icon"
      >
        <gl-icon :name="meta.iconName" class="icon" />
      </div>
    </template>
  </div>
</template>
