<script>
import { GlBadge, GlSprintf } from '@gitlab/ui';
import { isUserBusy } from '~/set_status_modal/utils';

export default {
  name: 'UserNameWithStatus',
  components: {
    GlBadge,
    GlSprintf,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    containerClasses: {
      type: String,
      required: false,
      default: '',
    },
    availability: {
      type: String,
      required: false,
      default: '',
    },
    pronouns: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasPronouns() {
      return this.pronouns !== null && this.pronouns.trim() !== '';
    },
    isBusy() {
      return isUserBusy(this.availability);
    },
  },
};
</script>
<template>
  <span :class="containerClasses">
    <gl-sprintf :message="s__('UserAvailability|%{author}%{badgeStart}Busy%{badgeEnd}')">
      <template #author
        ><span>{{ name }}</span
        ><span v-if="hasPronouns" class="gl-ml-1 gl-text-sm gl-font-normal gl-text-subtle"
          >({{ pronouns }})</span
        ></template
      >
      <template #badge="{ content }">
        <gl-badge v-if="isBusy" variant="warning" class="gl-ml-2">
          {{ content }}
        </gl-badge>
      </template>
    </gl-sprintf>
  </span>
</template>
