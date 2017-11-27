<script>
  import Icon from '~/vue_shared/components/icon.vue';
  import Issuable from '~/vue_shared/mixins/issuable';

  export default {
    mixins: [
      Issuable,
    ],
    components: {
      Icon,
    },
  };
</script>

<template>
  <div class="disabled-comment text-center">
    <span class="issuable-note-warning inline">
      <icon
        name="lock"
        :size="16"
        class="icon">
      </icon>
      <span>This {{ issuableDisplayName }} is locked. Only <b>project members</b> can comment.</span>
     </span>
  </div>
</template>
