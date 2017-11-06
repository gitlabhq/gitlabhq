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
      'setFileActive',
      'closeFile',
    ]),
  },
};
</script>

<template>
  <li
    :class="{ active : tab.active }"
    @click="setFileActive(tab)"
  >
    <button
      type="button"
      class="close-btn"
      @click.stop.prevent="closeFile({ file: tab })"
      :aria-label="closeLabel">
      <i
        class="fa"
        :class="changedClass"
        aria-hidden="true">
      </i>
    </button>

    <a
      href="#"
      class="repo-tab"
      :title="tab.url"
      @click.prevent.stop="setFileActive(tab)">
      {{tab.name}}
    </a>
  </li>
</template>
