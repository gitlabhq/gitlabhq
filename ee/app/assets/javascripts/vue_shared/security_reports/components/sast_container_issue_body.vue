<script>
/**
 * Renders SAST CONTAINER body text
 * [priority]: [name|link] in [link]:[line]
 */
import ReportLink from './report_link.vue';

export default {
  name: 'SastContainerIssueBody',

  components: {
    ReportLink,
  },

  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text append-right-5">
      <template v-if="issue.priority">{{ issue.priority }}:</template>

      <a
        v-if="issue.nameLink"
        :href="issue.nameLink"
        target="_blank"
        rel="noopener noreferrer nofollow"
      >
        {{ issue.name }}
      </a>
      <template v-else>
        {{ issue.name }}
      </template>
    </div>

    <report-link
      v-if="issue.path"
      :issue="issue"
    />
  </div>
</template>
