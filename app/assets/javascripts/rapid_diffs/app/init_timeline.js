import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { commitDiffDiscussionsStore } from '~/rapid_diffs/stores/instances/commit_discussions';
import CommitTimeline from './discussions/timeline.vue';

export function initTimeline(appData) {
  const timelineContainer = document.querySelector('[data-commit-timeline]');

  initVueApp({
    el: timelineContainer,
    name: 'CommitTimelineRoot',
    provide: {
      store: commitDiffDiscussionsStore,
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
    component: CommitTimeline,
  });
}
