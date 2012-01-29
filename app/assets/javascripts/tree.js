/**
 * Tree slider for code browse
 *
 */
var Tree = { 
  init: 
    function() { 
      (new Image).src = "/assets/ajax-loader-facebook.gif";

      $('#tree-slider .tree-item-file-name a, .breadcrumb a').live("click", function() {
        history.pushState({ path: this.path }, '', this.href)
        $("#tree-content-holder").hide("slide", { direction: "left" }, 150)
      })

      $("#tree-slider .tree-item").live('click', function(e){
        if(e.target.nodeName != "A") {
          link = $(this).find(".tree-item-file-name a");
          link.trigger("click");
        }
      });

      $('#tree-slider td.tree-item-file-name a, .breadcrumb a').live({ 
        "ajax:beforeSend": function() { $('.tree_progress').addClass("loading"); },
        "ajax:complete": function() { $('.tree_progress').removeClass("loading"); } 
      });
    }
}
