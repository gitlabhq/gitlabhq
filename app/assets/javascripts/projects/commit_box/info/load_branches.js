import axios from 'axios';
import { sanitize } from '~/lib/dompurify';
import { __ } from '~/locale';

export const loadBranches = containerEl => {
  if (!containerEl) {
    return;
  }

  const { commitPath } = containerEl.dataset;
  const branchesEl = containerEl.querySelector('.commit-info.branches');
  axios
    .get(commitPath)
    .then(({ data }) => {
      branchesEl.innerHTML = sanitize(data);
    })
    .catch(() => {
      branchesEl.textContent = __('Failed to load branches. Please try again.');
    });
};
