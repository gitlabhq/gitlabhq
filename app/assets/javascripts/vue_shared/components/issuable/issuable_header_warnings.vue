<script>
import { mapGetters } from 'vuex';
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
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
      ];
    },
  },
};
</script>

<template>
  <div class="gl-display-inline-block">
    <template v-for="meta in warningIconsMeta">
      <div v-if="meta.visible" :key="meta.iconName" class="issuable-warning-icon inline">
        <gl-icon :name="meta.iconName" :data-testid="meta.dataTestId" class="icon" />
      </div>
    </template>
  </div>
</template>
