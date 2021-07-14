import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { localTimeAgo } from '~/lib/utils/datetime_utility';
import initCompareAutocomplete from './compare_autocomplete';
import initTargetProjectDropdown from './target_project_dropdown';

const updateCommitList = (url, $loadingIndicator, $commitList, params) => {
  $loadingIndicator.show();
  $commitList.empty();

  return axios
    .get(url, {
      params,
    })
    .then(({ data }) => {
      $loadingIndicator.hide();
      $commitList.html(data);
      localTimeAgo($commitList.get(0).querySelectorAll('.js-timeago'));
    });
};

export default (mrNewCompareNode) => {
  const { sourceBranchUrl, targetBranchUrl } = mrNewCompareNode.dataset;
  initTargetProjectDropdown();

  const updateSourceBranchCommitList = () =>
    updateCommitList(
      sourceBranchUrl,
      $(mrNewCompareNode).find('.js-source-loading'),
      $(mrNewCompareNode).find('.mr_source_commit'),
      {
        ref: $(mrNewCompareNode).find("input[name='merge_request[source_branch]']").val(),
      },
    );
  const updateTargetBranchCommitList = () =>
    updateCommitList(
      targetBranchUrl,
      $(mrNewCompareNode).find('.js-target-loading'),
      $(mrNewCompareNode).find('.mr_target_commit'),
      {
        target_project_id: $(mrNewCompareNode)
          .find("input[name='merge_request[target_project_id]']")
          .val(),
        ref: $(mrNewCompareNode).find("input[name='merge_request[target_branch]']").val(),
      },
    );
  initCompareAutocomplete('branches', ($dropdown) => {
    if ($dropdown.is('.js-target-branch')) {
      updateTargetBranchCommitList();
    } else if ($dropdown.is('.js-source-branch')) {
      updateSourceBranchCommitList();
    }
  });
  updateSourceBranchCommitList();
  updateTargetBranchCommitList();
};
