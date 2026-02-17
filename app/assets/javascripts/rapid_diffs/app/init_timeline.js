import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import CommitTimeline from './discussions/timeline.vue';

export function initTimeline(appData) {
  const timelineContainer = document.querySelector('[data-commit-timeline]');

  // eslint-disable-next-line no-new
  new Vue({
    el: timelineContainer,
    name: 'CommitTimelineRoot',
    pinia,
    provide: {
      userPermissions: appData.userPermissions,
      endpoints: {
        discussions: appData.discussionsEndpoint,
        previewMarkdown: appData.previewMarkdownEndpoint,
        markdownDocs: appData.markdownDocsEndpoint,
        register: appData.registerPath,
        signIn: appData.signInPath,
        reportAbuse: appData.reportAbusePath,
      },
      noteableType: appData.noteableType,
    },
    render(h) {
      return h(CommitTimeline);
    },
  });
}
