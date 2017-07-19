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
      };
    },
    methods: {
      switchTab(e, index, tab) {
        this.selectTab(index);

        this.$emit('tab-selected', e, index, tab);
      },
      selectTab(index) {
        this.tabs.forEach((tab, i) => {
          tab.isActive = (index === i);
        });
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
        :class="{ active: tab.isActive, titleClass }"
        role="presentation"
        @click="switchTab($event, index, tab)">

        <a v-if="!tab.headerHtml">
          {{tab.title}}
        </a>
        <div v-else v-html="tab.headerHtml">
        </div>
      </li>
    </ul>

    <div class="tab-content">
      <slot></slot>
    </div>
  </div>
</template>
