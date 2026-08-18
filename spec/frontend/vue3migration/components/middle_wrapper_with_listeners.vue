<script>
import InnerEmitter from './inner_emitter.vue';

export default {
  name: 'MiddleWrapperWithListeners',
  components: {
    InnerEmitter,
  },
  data() {
    return {
      explicitCalled: false,
    };
  },
  methods: {
    setFocus() {
      this.explicitCalled = true;
    },
  },
};
</script>

<template>
  <div>
    <!-- Deliberate white-box usage: regression-tests @vue/compat's $listeners
         merge with explicit handlers (see hybrid_mode_spec.js). -->
    <!-- eslint-disable-next-line vue/no-deprecated-dollar-listeners-api -->
    <inner-emitter v-on="$listeners" @shown="setFocus" />
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <div v-if="explicitCalled" data-testid="explicit-called">Explicit handler called</div>
  </div>
</template>
