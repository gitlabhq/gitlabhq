/*= require protected_branch_access_dropdown */

(global => {
  global.gl = global.gl || {};

  class AllowedToPushDropdown extends gl.ProtectedBranchAccessDropdown {
  }

  global.gl.AllowedToPushDropdown = AllowedToPushDropdown;

})(window);
