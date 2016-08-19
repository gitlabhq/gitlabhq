/*= require protected_branch_access_dropdown */

(global => {
  global.gl = global.gl || {};

  class AllowedToMergeDropdown extends gl.ProtectedBranchAccessDropdown {
  }

  global.gl.AllowedToMergeDropdown = AllowedToMergeDropdown;

})(window);
