$(document).ready(function(){
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

