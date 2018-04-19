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
      type="button"
      class="btn btn-blank append-right-5"
      :aria-label="__('Stage changes')"
      :title="__('Stage changes')"
      data-container="body"
      @click.stop="stageChange(path)"
    >
      <icon
        name="mobile-issue-close"
        :size="12"
      />
    </button>
    <button
      v-tooltip
      type="button"
      class="btn btn-blank"
      :aria-label="__('Discard changes')"
      :title="__('Discard changes')"
      data-container="body"
      @click.stop="discardFileChanges(path)"
    >
      <icon
        name="remove"
        :size="12"
      />
    </button>
  </div>
</template>
