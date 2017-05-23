<script>
export default {
  name: 'MRWidgetCodeQualityIssues',
  props: {
    issues: {
      type: Array,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <ul class="mr-widget-code-quality-list">
    <li
      class="commit-sha"
      :class="{
        failed: type === 'failed',
        success: type === 'success'
      }
      "v-for="issue in issues">
      <i
        class="fa"
        :class="{
          'fa-minus': type === 'failed',
          'fa-plus': type === 'success'
        }"
        aria-hidden="true">
      </i>
      <span>
        {{issue.check_name}}
        {{issue.location.path}}
        {{issue.location.positions}}
        {{issue.location.lines}}
    </span>
    </li>
  </ul>
</template>
