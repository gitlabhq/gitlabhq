<script>
import { mapActions } from 'vuex';

export default {
  data() {
    return {
      tabMouseOver: false,
    };
  },
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
    showChangedIcon() {
      return this.tab.changed ? !this.tabMouseOver : false;
    },
  },

  methods: {
    ...mapActions([
      'setFileActive',
      'closeFile',
    ]),
    mouseOverTab() {
      if (this.tab.changed) {
        this.tabMouseOver = true;
      }
    },
    mouseOutTab() {
      if (this.tab.changed) {
        this.tabMouseOver = false;
      }
    },
  },
};
</script>

<template>
  <li
    @click="setFileActive(tab)"
    @mouseover="mouseOverTab"
    @mouseout="mouseOutTab"
  >
    <button
      type="button"
      class="multi-file-tab-close"
      @click.stop.prevent="closeFile({ file: tab })"
      :aria-label="closeLabel"
      :class="{
        'modified': tab.changed,
      }"
    >
      <i
        v-if="!showChangedIcon"
        class="fa fa-times close-icon"
        aria-hidden="true"
      >
      </i>
      <i
        v-else
        class="fa fa-circle unsaved-icon"
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
