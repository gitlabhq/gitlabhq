/**
 * Tree slider for code browse
 *
 */
var Tree = { 
  init: 
    function() { 
      $('#tree-slider td.tree-item-file-name a, #tree-breadcrumbs a').live("click", function() {
        history.pushState({ path: this.path }, '', this.href)
      })

      $("#tree-slider tr.tree-item").live('click', function(e){
        if(e.target.nodeName != "A") {
          e.stopPropagation();
          link = $(this).find("td.tree-item-file-name a");
          link.click();
          return false;
        }
      });
    }
}
