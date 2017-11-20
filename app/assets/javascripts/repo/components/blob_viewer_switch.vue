<script>
  import { mapActions, mapGetters } from 'vuex';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },
    computed: {
      ...mapGetters([
        'activeFile',
      ]),
      displayTooltip() {
        return `Display ${this.activeFile.simple.switcherTitle}`;
      },
      richTooltip() {
        return `Display ${this.activeFile.rich.switcherTitle}`;
      },
    },
    methods: {
      ...mapActions([
        'changeFileViewer',
      ]),
    },
  };
</script>

<template>
  <div
    class="btn-group js-blob-viewer-switcher"
    role="group"
  >
    <button
      v-tooltip
      type="button"
      class="btn btn-default btn-sm js-blob-viewer-switch-btn"
      :class="{
        active: activeFile.currentViewer === 'simple',
      }"
      :title="displayTooltip"
      data-container="body"
      data-viewer="simple"
      @click="changeFileViewer({ file: activeFile, type: 'simple' })"
    >
      <i
        class="fa"
        :class="'fa-' + activeFile.simple.icon"
        aria-hidden="true"
      >
      </i>
    </button>
    <button
      v-tooltip
      type="button"
      class="btn btn-default btn-sm js-blob-viewer-switch-btn"
      :class="{
        active: activeFile.currentViewer === 'rich',
      }"
      :title="richTooltip"
      data-container="body"
      data-viewer="rich"
      @click="changeFileViewer({ file: activeFile, type: 'rich' })"
    >
      <i
        class="fa"
        :class="'fa-' + activeFile.rich.icon"
        aria-hidden="true"
      >
      </i>
    </button>
  </div>
</template>
