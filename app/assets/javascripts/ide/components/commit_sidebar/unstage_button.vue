<script>
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    file: {
      type: Object,
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
      type="button"
      class="btn btn-blank"
      :aria-label="__('Unstage change')"
      @click="unstageChange(file)"
    >
      <icon
        name="history"
        :size="12"
      />
    </button>
  </div>
</template>
