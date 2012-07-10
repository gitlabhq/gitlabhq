// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery.ui.all
//= require jquery_ujs
//= require jquery.ui.selectmenu
//= require jquery.tagify
//= require jquery.cookie
//= require jquery.endless-scroll
//= require jquery.highlight
//= require jquery.waitforimages
//= require bootstrap-modal
//= require modernizr
//= require chosen-jquery
//= require raphael
//= require branch-graph
//= require_tree .

$(document).ready(function(){

  $(".one_click_select").live("click", function(){
    $(this).select();
  });


  $('body').on('ajax:complete, ajax:beforeSend, submit', 'form', function(e){
    var buttons = $('[type="submit"]', this);
    switch( e.type ){
      case 'ajax:beforeSend':
      case 'submit':
        buttons.attr('disabled', 'disabled');
      break;
      case ' ajax:complete':
      default:
        buttons.removeAttr('disabled');
      break;
    }
  })

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

  /**
   * Commit show suppressed diff
   *
   */
  $(".supp_diff_link").bind("click", function() {
    showDiff(this);
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

(function($){
    var _chosen = $.fn.chosen;
    $.fn.extend({
        chosen: function(options) {
            var default_options = {'search_contains' : 'true'};
            $.extend(default_options, options);
            return _chosen.apply(this, [default_options]);
    }})
})(jQuery);


function ajaxGet(url) { 
  $.ajax({type: "GET", url: url, dataType: "script"}); 
}
