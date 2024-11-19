import { initMarkdownEditor } from 'ee_else_ce/pages/projects/merge_requests/init_markdown_editor';

import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { GitLabDropdown } from '~/deprecated_jquery_dropdown/gl_dropdown';

import initMergeRequest from '~/pages/projects/merge_requests/init_merge_request';
import initCheckFormState from './check_form_state';
import initFormUpdate from './update_form';

function initTargetBranchSelector() {
  const targetBranch = document.querySelector('.js-target-branch');
  const { selected, fieldName, refsUrl } = targetBranch?.dataset ?? {};
  const formField = document.querySelector(`input[name="${fieldName}"]`);

  if (targetBranch && refsUrl && formField) {
    /* eslint-disable-next-line no-new */
    new GitLabDropdown(targetBranch, {
      selectable: true,
      filterable: true,
      filterRemote: Boolean(refsUrl),
      filterInput: 'input[type="search"]',
      data(term, callback) {
        const params = {
          search: term,
        };

        axios
          .get(refsUrl, {
            params,
          })
          .then(({ data }) => {
            callback(data);
          })
          .catch(() =>
            createAlert({
              message: __('Error fetching branches'),
            }),
          );
      },
      renderRow(branch) {
        const item = document.createElement('li');
        const link = document.createElement('a');

        link.setAttribute('href', '#');
        link.dataset.branch = branch;
        link.classList.toggle('is-active', branch === selected);
        link.textContent = branch;

        item.appendChild(link);

        return item;
      },
      id(obj, $el) {
        return $el.data('id');
      },
      toggleLabel(obj, $el) {
        return $el.text().trim();
      },
      clicked({ $el, e }) {
        e.preventDefault();

        const branchName = $el[0].dataset.branch;

        formField.setAttribute('value', branchName);
      },
    });
  }
}

initMergeRequest();
initFormUpdate();
initCheckFormState();
initTargetBranchSelector();
initMarkdownEditor();
