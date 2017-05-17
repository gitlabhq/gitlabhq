<script>
export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    issues: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <p>{{title}}</p>
    <ul>
      <li v-for="issue in issues">
        <span class="js-issue-name">
          {{issue.check_name}}
        </span>
        <span class="js-issue-location">
          {{issue.location.path}}
        </span>
        <span
          v-if="issue.location.positions"
          class="js-issue-position">
          {{issue.location.positions}}
        </span>
        <span
          v-if="issue.location.lines"
          class="js-issue-lines">
          {{issue.location.lines}}
        </span>
      </li>
    </ul>
  </div>
</template>
