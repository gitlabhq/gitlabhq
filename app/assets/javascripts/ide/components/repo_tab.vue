<script>
  import { mapActions } from 'vuex';
  import fileIcon from '../../vue_shared/components/file_icon.vue';
  import icon from '../../vue_shared/components/icon.vue';

  export default {
    components: {
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
        name="file-modified"
        :size="12"
        css-classes="multi-file-modified"
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
    </div>
  </li>
</template>
