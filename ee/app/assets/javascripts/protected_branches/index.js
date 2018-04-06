/* eslint-disable no-unused-vars */

import $ from 'jquery';
import ProtectedBranchCreate from './protected_branch_create';
import ProtectedBranchEditList from './protected_branch_edit_list';

$(() => {
  const protectedBranchCreate = new ProtectedBranchCreate();
  const protectedBranchEditList = new ProtectedBranchEditList();
});
