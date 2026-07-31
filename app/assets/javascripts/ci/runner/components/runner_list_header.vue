<script>
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

export default {
  name: 'RunnerListHeader',
  components: {
    PageHeading,
  },
  mixins: [glSlotsMixin],
};
</script>
<template>
  <page-heading class="gl-mb-3">
    <template #heading>
      <slot name="title"></slot>
    </template>

    <template v-if="glSlots().description" #description>
      <slot name="description"></slot>
    </template>

    <template v-if="glSlots().actions" #actions>
      <slot name="actions"></slot>
    </template>
  </page-heading>
</template>
