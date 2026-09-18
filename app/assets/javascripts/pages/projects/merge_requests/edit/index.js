import { initMarkdownEditor } from 'ee_else_ce/pages/projects/merge_requests/init_markdown_editor';

import initMergeRequest from '~/pages/projects/merge_requests/init_merge_request';
import initCheckFormState from './check_form_state';
import initTargetBranchRefSelector from './init_target_branch_ref_selector';
import initFormUpdate from './update_form';

initMergeRequest();
initFormUpdate();
initCheckFormState();
initTargetBranchRefSelector();
initMarkdownEditor();
