import Vue from 'vue';
import { initReportAbuse } from '~/projects/report_abuse';
import MrMoreDropdown from '~/vue_shared/components/mr_more_dropdown.vue';

export const initMrMoreDropdown = () => {
  const el = document.querySelector('.js-mr-more-dropdown');

  if (!el) {
    return false;
  }

  const {
    mergeRequest,
    projectPath,
    url,
    editUrl,
    isCurrentUser,
    isLoggedIn,
    canUpdateMergeRequest,
    open,
    merged,
    sourceProjectMissing,
    clipboardText,
    reportedUserId,
  } = el.dataset;

  let mr;

  try {
    mr = JSON.parse(mergeRequest);
  } catch {
    mr = {};
  }

  return new Vue({
    el,
    provide: {
      reportAbusePath: el.dataset.reportAbusePath,
    },
    beforeCreate() {
      initReportAbuse();
    },
    render: (createElement) =>
      createElement(MrMoreDropdown, {
        props: {
          mr,
          projectPath,
          url,
          editUrl,
          isCurrentUser,
          isLoggedIn: Boolean(isLoggedIn),
          canUpdateMergeRequest,
          open,
          isMerged: merged,
          sourceProjectMissing,
          clipboardText,
          reportedUserId: Number(reportedUserId),
        },
      }),
  });
};
