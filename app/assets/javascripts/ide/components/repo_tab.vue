<script>
import { mapActions } from 'vuex';

export default {
  props: {
    tab: {
      type: Object,
      required: true,
    },
  },

  computed: {
    closeLabel() {
      if (this.tab.changed || this.tab.tempFile) {
        return `${this.tab.name} changed`;
      }
      return `Close ${this.tab.name}`;
    },
    changedClass() {
      const tabChangedObj = {
        'fa-times close-icon': !this.tab.changed && !this.tab.tempFile,
        'fa-circle unsaved-icon': this.tab.changed || this.tab.tempFile,
      };
      return tabChangedObj;
    },
  },

  methods: {
    ...mapActions([
      'closeFile',
    ]),
    clickFile(tab) {
      this.$router.push(`/project${tab.url}`);
    },
  },
};
</script>

<template>
  <li
    @click="clickFile(tab)"
  >
    <button
      type="button"
      class="multi-file-tab-close"
      @click.stop.prevent="closeFile({ file: tab })"
      :aria-label="closeLabel"
      :class="{
        'modified': tab.changed,
      }"
      :disabled="tab.changed"
    >
      <i
        class="fa"
        :class="changedClass"
        aria-hidden="true"
      >
      </i>
    </button>

    <div
      class="multi-file-tab"
      :class="{active : tab.active }"
      :title="tab.url"
    >
      {{ tab.name }}
    </div>
  </li>
</template>
