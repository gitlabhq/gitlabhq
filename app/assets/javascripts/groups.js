this.GroupMembers = (function() {
  function GroupMembers() {
    $('li.group_member').bind('ajax:success', function() {
      return $(this).fadeOut();
    });
  }

  return GroupMembers;

})();
