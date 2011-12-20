/**
 * Tree slider for code browse
 *
 */
var Tree = { 
  init: 
    function() { 
      (new Image).src = "/assets/ajax-loader-tree.gif";

      $('#tree-slider td.tree-item-file-name a, #tree-breadcrumbs a').live("click", function() {
        history.pushState({ path: this.path }, '', this.href)
        $("#tree-content-holder").hide("slide", { direction: "left" }, 150)
      })

      $("#tree-slider tr.tree-item").live('click', function(e){
        if(e.target.nodeName != "A") {
          link = $(this).find("td.tree-item-file-name a");
          link.trigger("click");
        }
      });

      $('#tree-slider td.tree-item-file-name a, #tree-breadcrumbs a').live({ 
        "ajax:beforeSend": function() { $('h2.icon').addClass("loading") },
        "ajax:complete": function() { $('h2.icon').removeClass("loading")} 
      });
    }
}
