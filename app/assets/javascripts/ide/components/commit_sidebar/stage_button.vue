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
    ...mapActions(['stageChange', 'discardFileChanges']),
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
      class="btn btn-blank append-right-5"
      :aria-label="__('Stage change')"
      @click.stop="stageChange(file)"
    >
      <icon
        name="mobile-issue-close"
        :size="12"
      />
    </button>
    <button
      type="button"
      class="btn btn-blank"
      :aria-label="__('Discard change')"
      @click.stop="discardFileChanges(file)"
    >
      <icon
        name="remove"
        :size="12"
      />
    </button>
  </div>
</template>
