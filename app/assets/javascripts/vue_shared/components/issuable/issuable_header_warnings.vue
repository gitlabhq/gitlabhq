<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
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
        },
        {
          iconName: 'eye-slash',
          visible: this.isConfidential,
          dataTestId: 'confidential',
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
    <template v-for="meta in warningIconsMeta">
      <div
        v-if="meta.visible"
        :key="meta.iconName"
        v-gl-tooltip
        :data-testid="meta.dataTestId"
        :title="meta.tooltip || null"
        class="issuable-warning-icon inline"
      >
        <gl-icon :name="meta.iconName" class="icon" />
      </div>
    </template>
  </div>
</template>
