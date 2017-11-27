<script>
  import Icon from '../../vue_shared/components/icon.vue';

  export default {
    component: {
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
      <span>This issue is locked. Only <b>project members</b> can comment.</span>
     </span>
  </div>
</template>
