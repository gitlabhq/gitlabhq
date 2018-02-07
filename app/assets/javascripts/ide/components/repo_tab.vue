<script>
  import { mapActions } from 'vuex';
  import fileStatusIcon from './repo_file_status_icon.vue';
  import fileIcon from '../../vue_shared/components/file_icon.vue';
  import icon from '../../vue_shared/components/icon.vue';

  export default {
    components: {
      fileStatusIcon,
      fileIcon,
      icon,
    },
    props: {
      tab: {
        type: Object,
        required: true,
      },
    },
    data() {
      return {
        tabMouseOver: false,
      };
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
      changedIcon() {
        return this.tab.tempFile ? 'file-addition' : 'file-modified';
      },
      changedIconClass() {
        return this.tab.tempFile ? 'multi-file-addition' : 'multi-file-modified';
      },
    },

    methods: {
      ...mapActions([
        'closeFile',
      ]),
      clickFile(tab) {
        this.$router.push(`/project${tab.url}`);
      },
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
    @click="clickFile(tab)"
    @mouseover="mouseOverTab"
    @mouseout="mouseOutTab"
  >
    <button
      type="button"
      class="multi-file-tab-close"
      @click.stop.prevent="closeFile(tab)"
      :aria-label="closeLabel"
    >
      <icon
        v-if="!showChangedIcon"
        name="close"
        :size="12"
      />
      <icon
        v-else
        :name="changedIcon"
        :size="12"
        :css-classes="changedIconClass"
      />
    </button>

    <div
      class="multi-file-tab"
      :class="{active : tab.active }"
      :title="tab.url"
    >
      <file-icon
        :file-name="tab.name"
        :size="16"
      />
      {{ tab.name }}
      <file-status-icon
        :file="tab"
      />
    </div>
  </li>
</template>
