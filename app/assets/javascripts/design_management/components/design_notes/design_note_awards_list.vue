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
    class="gl-px-2 gl-mt-5"
    @award="$emit('award', $event)"
  />
</template>
