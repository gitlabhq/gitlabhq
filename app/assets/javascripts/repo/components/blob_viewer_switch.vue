<script>
  import { mapActions, mapGetters } from 'vuex';
  import tooltip from '../../vue_shared/directives/tooltip.js';

  export default {
    directives: {
      tooltip,
    },
    computed: {
      ...mapGetters([
        'activeFile',
      ]),
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
    class="btn-group"
    role="group"
  >
    <button
      v-tooltip
      type="button"
      class="btn btn-default btn-sm"
      :class="{
        active: activeFile.currentViewer === 'simple',
      }"
      title="Display source"
      data-container="body"
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
      class="btn btn-default btn-sm"
      :class="{
        active: activeFile.currentViewer === 'rich',
      }"
      title="Display rendered file"
      data-container="body"
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
