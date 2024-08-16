<script>
export default {
  name: 'RunnerListHeader',
};
</script>
<template>
  <header class="gl-my-5 gl-flex gl-items-start gl-flex-wrap gl-justify-between">
    <h1 v-if="$scopedSlots.title" class="gl-mt-0 gl-mb-3 gl-font-size-h1 header-title">
      <slot name="title"></slot>
    </h1>
    <div v-if="$scopedSlots.actions" class="gl-flex gl-gap-3">
      <slot name="actions"></slot>
    </div>
  </header>
</template>
