function initGraphNav() { 
  $("body").keydown(function(e) {
    if(e.keyCode == 37) { // left
      $(".graph svg").animate({ left: "+=400" });
    } else if(e.keyCode == 39) { // right
      $(".graph svg").animate({ left: "-=400" });
    }
  });
}
