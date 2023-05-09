import axios from 'axios';
import { sanitize } from '~/lib/dompurify';
import { __ } from '~/locale';
import { initDetailsButton } from './init_details_button';

export const loadBranches = (containerSelector = '.js-commit-box-info') => {
  const containerEl = document.querySelector(containerSelector);
  if (!containerEl) {
    return;
  }

  const { commitPath } = containerEl.dataset;
  const branchesEl = containerEl.querySelector('.commit-info.branches');
  axios
    .get(commitPath)
    .then(({ data }) => {
      branchesEl.innerHTML = sanitize(data);

      initDetailsButton();
    })
    .catch(() => {
      branchesEl.textContent = __('Failed to load branches. Please try again.');
    });
};
