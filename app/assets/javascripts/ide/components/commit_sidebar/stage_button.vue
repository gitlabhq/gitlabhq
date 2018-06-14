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
      v-tooltip
      :aria-label="__('Stage changes')"
      :title="__('Stage changes')"
      type="button"
      class="btn btn-blank append-right-5"
      data-container="body"
      @click.stop="stageChange(path)"
    >
      <icon
        :size="12"
        name="mobile-issue-close"
      />
    </button>
    <button
      v-tooltip
      :aria-label="__('Discard changes')"
      :title="__('Discard changes')"
      type="button"
      class="btn btn-blank"
      data-container="body"
      @click.stop="discardFileChanges(path)"
    >
      <icon
        :size="12"
        name="remove"
      />
    </button>
  </div>
</template>
