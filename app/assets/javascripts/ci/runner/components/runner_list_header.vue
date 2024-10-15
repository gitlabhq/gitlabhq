<script>
import PageHeading from '~/vue_shared/components/page_heading.vue';

export default {
  name: 'RunnerListHeader',
  components: {
    PageHeading,
  },
};
</script>
<template>
  <page-heading>
    <template #heading>
      <slot name="title"></slot>
    </template>

    <template #description>
      <slot name="description"></slot>
    </template>

    <template v-if="$scopedSlots.actions" #actions>
      <slot name="actions"></slot>
    </template>
  </page-heading>
</template>
