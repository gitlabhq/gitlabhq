<script>
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
  },
  methods: {
    ...mapActions(['unstageChange']),
  },
};
</script>

<template>
  <div
    v-once
    class="multi-file-discard-btn"
  >
    <button
      v-tooltip
      type="button"
      class="btn btn-blank"
      :aria-label="__('Unstage changes')"
      :title="__('Unstage changes')"
      data-container="body"
      @click="unstageChange(path)"
    >
      <icon
        name="history"
        :size="12"
      />
    </button>
  </div>
</template>
