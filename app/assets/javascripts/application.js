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

  $('select#branch').selectmenu({style:'popup', width:200});
  $('select#tag').selectmenu({style:'popup', width:200});

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

function updatePage(data){
  $.ajax({type: "GET", url: location.href, data: data, dataType: "script"});
}

function showMenu() {
  $(this).toggleClass('hover');
}

function resetMenu() {
  $(this).removeClass("hover");
}


