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
  <page-heading class="gl-mb-3">
    <template #heading>
      <slot name="title"></slot>
    </template>

    <template v-if="$scopedSlots.description" #description>
      <slot name="description"></slot>
    </template>

    <template v-if="$scopedSlots.actions" #actions>
      <slot name="actions"></slot>
    </template>
  </page-heading>
</template>
