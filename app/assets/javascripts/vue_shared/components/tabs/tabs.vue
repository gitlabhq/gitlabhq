<script>
  export default {
    name: 'tabs',
    props: {
      defaultIndex: {
        default: 0,
        type: Number
      },
      containerClass: {
        type: String,
        required: false,
        default: '',
      },
      titleClass: {
        type: String,
        required: false,
        default: '',
      }
    },
    data() {
      return {
        tabs: [],
        selectedTab: this.defaultIndex,
      };
    },
    methods: {
      switchTab(e, index, tab) {
        this.selectedTab = index;

        this.$emit('tabSelected', e, index, tab);
      },

      selectTab(index) {
        this.tabs.forEach((tab, i) => {
          tab.isActive = index === i;
        });
      },

      closeTab(tab) {
        this.$emit('closeTab', tab);
      },
    },

    watch: {
      defaultIndex() {
        this.selectedTab = this.defaultIndex;

      },
      selectedTab(){
        this.selectTab(this.selectedTab);
      }
    },

    mounted() {
      this.tabs = this.$children;

      this.selectTab(this.defaultIndex);
    }
  }
</script>

<template>
  <div>
    <ul
      class="nav-links"
      :class="containerClass"
      role="tablist">
      <li
        v-for="(tab, index) in tabs"
        :class="{ active: tab.isActive }"
        role="presentation"
        @click="switchTab($event, index, tab)">

        <a v-if="!tab.headerHtml">
          {{tab.title}}
        </a>
        <div
          v-else
          v-html="tab.headerHtml">
        </div>

        <button
          v-if="tab.isClosable"
          class="tab-close-button btn-transparent btn-blank"
          @click.stop="closeTab(tab)">
          x
        </button>
      </li>
    </ul>

    <div class="tab-content">
      <slot></slot>
    </div>
  </div>
</template>
