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
//= require_tree .

$(function(){
  $(".one_click_select").live("click", function(){
    $(this).select();
  });

  $('select#branch').selectmenu({style:'popup', width:200});
  $('select#tag').selectmenu({style:'popup', width:200});
});

function updatePage(data){
  $.ajax({type: "GET", url: location.href, data: data, dataType: "script"});
}
