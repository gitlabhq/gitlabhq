// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require jquery.ui.selectmenu
//= require jquery.tagify
//= require jquery.cookie
//= require jquery.endless-scroll
//= require jquery.highlight
//= require bootstrap-modal
//= require modernizr
//= require chosen
//= require raphael
//= require branch-graph
//= require_tree .

$(document).ready(function(){
  $(".one_click_select").live("click", function(){
    $(this).select();
  });

  $(".account-box").mouseenter(showMenu);
  $(".account-box").mouseleave(resetMenu);

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

  /**
   * Focus search field by pressing 's' key
   */
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

function updatePage(data){
  $.ajax({type: "GET", url: location.href, data: data, dataType: "script"});
}

function showMenu() {
  $(this).toggleClass('hover');
}

function resetMenu() {
  $(this).removeClass("hover");
}

function slugify(text) {
  return text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase();
}

function showDiff(link) { 
  $(link).next('table').show();
  $(link).remove();
}
