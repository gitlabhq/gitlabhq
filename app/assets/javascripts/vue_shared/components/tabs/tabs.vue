<script>
  export default {
    name: 'tabs',
    props: {
      defaultIndex: {
        default: 0,
        type: Number
      },
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
    <ul class="nav nav-tabs" role="tablist">
      <li
        v-for="(tab, index) in tabs"
        :class="{ active: tab.isActive }"
        role="presentation">
        <a @click="switchTab($event, index, tab)">
          {{tab.title}}
        </a>
      </li>
    </ul>

    <div class="tab-content">
      <slot></slot>
    </div>

  </div>
</template>
