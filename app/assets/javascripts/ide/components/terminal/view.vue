<!-- eslint-disable vue/multi-word-component-names -->
<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import EmptyState from './empty_state.vue';

export default {
  components: {
    EmptyState,
    TerminalSession: () => import(/* webpackChunkName: 'ide_terminal' */ './session.vue'),
  },
  computed: {
    ...mapState('terminal', ['isShowSplash', 'paths']),
    ...mapGetters('terminal', ['allCheck']),
  },
  methods: {
    ...mapActions('terminal', ['startSession', 'hideSplash']),
    start() {
      this.startSession();
      this.hideSplash();
    },
  },
};
</script>

<template>
  <div class="gl-h-full">
    <div v-if="isShowSplash" class="flex-column justify-content-center gl-flex gl-h-full">
      <empty-state
        :is-loading="allCheck.isLoading"
        :is-valid="allCheck.isValid"
        :message="allCheck.message"
        :help-path="paths.webTerminalHelpPath"
        :illustration-path="paths.webTerminalSvgPath"
        @start="start()"
      />
    </div>
    <template v-else>
      <terminal-session />
    </template>
  </div>
</template>
