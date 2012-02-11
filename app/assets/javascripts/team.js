function backToMembers(){
  $("#new_team_member").hide("slide", { direction: "right" }, 150, function(){
    $("#team-table").show("slide", { direction: "left" }, 150, function() { 
      $("#new_team_member").remove();
      $(".add_new").show();
    });
  });
}
