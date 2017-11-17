<script>
  export default {
    name: 'PipelineNavigationTabs',
    props: {
      tabs: {
        type: Array,
        required: true,
      },
    },
    mounted() {
      $(document).trigger('init.scrolling-tabs');
    },
    methods: {
      shouldRenderBadge(count) {
        // 0 is valid in a badge, but evaluates to false, we need to check for undefined
        return count !== undefined;
      },

      onTabClick(tab) {
        this.$emit('onChangeTab', tab.scope);
      },
    },
};
</script>
<template>
  <ul class="nav-links scrolling-tabs">
    <li
      v-for="(tab, i) in tabs"
      :key="i"
      :class="{
        active: tab.isActive,
      }"
      >
      <a
        role="button"
        @click="onTabClick(tab)"
        :class="`js-pipelines-tab-${tab.scope}`"
        >
        {{ tab.name }}

        <span
          v-if="shouldRenderBadge(tab.count)"
          class="badge"
          >
          {{tab.count}}
        </span>

      </a>
    </li>
  </ul>
</template>
