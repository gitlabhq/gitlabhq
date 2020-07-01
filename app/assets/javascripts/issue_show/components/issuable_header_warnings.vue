<script>
import { mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  computed: {
    ...mapState({
      confidential: ({ noteableData }) => noteableData.confidential,
      dicussionLocked: ({ noteableData }) => noteableData.discussion_locked,
    }),
  },
};
</script>

<template>
  <div class="gl-display-inline-block">
    <div v-if="confidential" class="issuable-warning-icon inline">
      <icon class="icon" name="eye-slash" data-testid="confidential" />
    </div>

    <div v-if="dicussionLocked" class="issuable-warning-icon inline">
      <icon class="icon" name="lock" data-testid="locked" />
    </div>
  </div>
</template>
