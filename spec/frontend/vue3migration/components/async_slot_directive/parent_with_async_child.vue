<script>
const testDirective = {
  bind(el) {
    el.dataset.directiveApplied = 'true';
  },
  inserted(el) {
    el.dataset.directiveInserted = 'true';
  },
};

export default {
  name: 'ParentWithAsyncChild',
  directives: {
    testDirective,
  },
  components: {
    AsyncChild: () => import('./child_with_slot.vue'),
  },
};
</script>

<template>
  <div>
    <async-child>
      <template #content>
        <span v-test-directive data-testid="slot-content">{{ __('Content') }}</span>
      </template>
    </async-child>
  </div>
</template>
