<script>
import AwardsList from '~/vue_shared/components/awards_list.vue';

export default {
  components: {
    AwardsList,
  },
  props: {
    awards: {
      type: Array,
      required: true,
    },
    canAwardEmoji: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    currentUserId() {
      return window.gon.current_user_id;
    },
  },
};
</script>

<template>
  <awards-list
    :awards="awards"
    :can-award-emoji="canAwardEmoji"
    :current-user-id="currentUserId"
    class="gl-mt-5 gl-px-2"
    @award="$emit('award', $event)"
  />
</template>
