function backToMembers(){
  $("#team_member_new").hide("slide", { direction: "right" }, 150, function(){
    $("#team-table").show("slide", { direction: "left" }, 150, function() { 
      $("#team_member_new").remove();
      $(".add_new").show();
    });
  });
}
