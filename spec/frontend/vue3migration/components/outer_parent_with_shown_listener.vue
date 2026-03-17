<script>
import MiddleWrapperWithListeners from './middle_wrapper_with_listeners.vue';

export default {
  name: 'OuterParentWithShownListener',
  components: {
    MiddleWrapperWithListeners,
  },
  data() {
    return {
      parentCalled: false,
    };
  },
  methods: {
    handleShown() {
      this.parentCalled = true;
    },
  },
};
</script>

<template>
  <div>
    <middle-wrapper-with-listeners @shown="handleShown" />
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <div v-if="parentCalled" data-testid="parent-called">Parent handler called</div>
  </div>
</template>
