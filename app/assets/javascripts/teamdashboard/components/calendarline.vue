<script>
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  props: {
    milestone: {
      type: Object,
      required: true,
    },
  },
  components: {
    userAvatarImage,
  }
}
</script>
<template>
  <div class="row">
    Calendar
  </div>
</template>
