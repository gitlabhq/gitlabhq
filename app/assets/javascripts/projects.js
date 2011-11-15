$(document).ready(function(){
  $('#tree-slider td.tree-item-file-name a, #tree-breadcrumbs a').live("click", function() {
    history.pushState({ path: this.path }, '', this.href)
  })

  $("#tree-slider tr.tree-item").live('click', function(e){
    if(e.target.nodeName != "A") {
      e.stopPropagation();
      $(this).find("td.tree-item-file-name a").click();
      return false;
    }
  });

  $("#projects-list .project").live('click', function(e){
    if(e.target.nodeName != "A" && e.target.nodeName != "INPUT") {
      location.href = $(this).attr("url");
      e.stopPropagation();
      return false;
    }
  });

  $("#issues-table .issue").live('click', function(e){
    if(e.target.nodeName != "A" && e.target.nodeName != "INPUT") {
      location.href = $(this).attr("url");
      e.stopPropagation();
      return false;
    }
  });

  $(document).keypress(function(e) {
    if( $(e.target).is(":input") ) return;
    switch(e.which)  {
      case 115:  focusSearch();
        e.preventDefault();
    }
  });

});

function focusSearch() {
  $("#search").focus();
}

function taggifyForm(){
  var tag_field = $('#tag_field').tagify();

  tag_field.tagify('inputField').autocomplete({
      source: '/tags.json'
  });

  $('form').submit( function() {
    var tag_field = $('#tag_field')
       tag_field.val( tag_field.tagify('serialize') );
       return true;
  });
}

