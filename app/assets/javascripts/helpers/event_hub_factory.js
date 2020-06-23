import Vue from 'vue';

/**
 * Return a Vue like event hub
 *
 * - $on
 * - $off
 * - $once
 * - $emit
 *
 * Please note, this was once implemented with `mitt`, but since then has been reverted
 * because of some API issues. https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35074
 *
 * We'd like to shy away from using a full fledged Vue instance from this in the future.
 */
export default () => {
  return new Vue();
};
