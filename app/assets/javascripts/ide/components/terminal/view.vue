<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import EmptyState from './empty_state.vue';
import TerminalSession from './session.vue';

export default {
  components: {
    EmptyState,
    TerminalSession,
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
  <div class="h-100">
    <div v-if="isShowSplash" class="h-100 d-flex flex-column justify-content-center">
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
