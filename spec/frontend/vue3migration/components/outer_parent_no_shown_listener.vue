<script>
import MiddleWrapperWithListeners from './middle_wrapper_with_listeners.vue';

export default {
  name: 'OuterParentNoShownListener',
  components: {
    MiddleWrapperWithListeners,
  },
};
</script>

<template>
  <div>
    <middle-wrapper-with-listeners />
  </div>
</template>
