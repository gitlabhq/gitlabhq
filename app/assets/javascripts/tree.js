/**
 * Tree slider for code browse
 *
 */
var Tree = { 
  init: 
    function() { 
      $('#tree-slider .tree-item-file-name a, .breadcrumb li > a').live("click", function() {
        $("#tree-content-holder").hide("slide", { direction: "left" }, 150)
      })

      $('.project-refs-form').live({
        "ajax:beforeSend": function() { 
          $("#tree-content-holder").hide("slide", { direction: "left" }, 150); 
        }
      })

      $("#tree-slider .tree-item").live('click', function(e){
        if(e.target.nodeName != "A") {
          link = $(this).find(".tree-item-file-name a");
          link.trigger("click");
        }
      });

      $('#tree-slider .tree-item-file-name a, .breadcrumb a, .project-refs-form').live({ 
        "ajax:beforeSend": function() { $('.tree_progress').addClass("loading"); },
        "ajax:complete": function() { $('.tree_progress').removeClass("loading"); } 
      });
    }
}
