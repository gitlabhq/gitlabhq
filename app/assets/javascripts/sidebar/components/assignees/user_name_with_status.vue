<script>
import { GlSprintf } from '@gitlab/ui';
import { isUserBusy } from '~/set_status_modal/utils';

export default {
  name: 'UserNameWithStatus',
  components: {
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
    <gl-sprintf :message="s__('UserAvailability|%{author} %{spanStart}(Busy)%{spanEnd}')">
      <template #author
        >{{ name }}
        <span v-if="hasPronouns" class="gl-text-gray-500 gl-font-sm gl-font-weight-normal"
          >({{ pronouns }})</span
        ></template
      >
      <template #span="{ content }"
        ><span v-if="isBusy" class="gl-text-gray-500 gl-font-sm gl-font-weight-normal">{{
          content
        }}</span>
      </template>
    </gl-sprintf>
  </span>
</template>
