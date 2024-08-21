<script>
export default {
  name: 'RunnerListHeader',
};
</script>
<template>
  <header class="gl-my-5 gl-flex gl-flex-wrap gl-items-start gl-justify-between">
    <h1 v-if="$scopedSlots.title" class="header-title gl-mb-3 gl-mt-0 gl-text-size-h1">
      <slot name="title"></slot>
    </h1>
    <div v-if="$scopedSlots.actions" class="gl-flex gl-gap-3">
      <slot name="actions"></slot>
    </div>
  </header>
</template>
