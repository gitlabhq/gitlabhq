import Vue from 'vue';
import CommitCommentsButton from './components/commit_comments_button.vue';

export default function initCommitCommentsButton() {
  const el = document.querySelector('#js-commit-comments-button');

  if (!el) {
    return false;
  }

  const { commentsCount } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(CommitCommentsButton, { props: { commentsCount: Number(commentsCount) } }),
  });
}
