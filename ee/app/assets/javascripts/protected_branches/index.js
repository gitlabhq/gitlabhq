/* eslint-disable no-unused-vars */
import './protected_branch_access_dropdown';
import './protected_branch_create';
import './protected_branch_dropdown';
import './protected_branch_edit';
import './protected_branch_edit_list';

$(() => {
  const protectedBranchCreate = new gl.ProtectedBranchCreate();
  const protectedBranchEditList = new gl.ProtectedBranchEditList();
});
