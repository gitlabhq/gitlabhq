<script>
import IssueItem from './issue_item.vue';

export default {
  props: {
    issues: {
      type: Array,
      required: true,
    },
  },
  components: {
    IssueItem
  },
  methods: {
    
  }
}
</script>
<template>
  <ul class="well-list issues-sortable-list" data-state="unassigned" id="issues-list-unassigned" style="min-height: 0px;">
    <template v-for="issue in issues">
      <IssueItem :issue="issue"/>
    </template>
  </ul>
</template>
