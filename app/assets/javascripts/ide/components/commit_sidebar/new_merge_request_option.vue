<script>
import { createNamespacedHelpers } from 'vuex';

const {
  mapState: mapCommitState,
  mapActions: mapCommitActions,
  mapGetters: mapCommitGetters,
} = createNamespacedHelpers('commit');

export default {
  computed: {
    ...mapCommitState(['shouldCreateMR']),
    ...mapCommitGetters(['shouldHideNewMrOption']),
  },
  methods: {
    ...mapCommitActions(['toggleShouldCreateMR']),
  },
};
</script>

<template>
  <fieldset v-if="!shouldHideNewMrOption">
    <hr class="my-2" />
    <label class="mb-0 js-ide-commit-new-mr">
      <input
        :checked="shouldCreateMR"
        type="checkbox"
        data-qa-selector="start_new_mr_checkbox"
        @change="toggleShouldCreateMR"
      />
      <span class="prepend-left-10">
        {{ __('Start a new merge request') }}
      </span>
    </label>
  </fieldset>
</template>
