$(document).ready(function(){
  $(".day-commits-table li.commit").live('click', function(e){
    if(e.target.nodeName != "A") {
      location.href = $(this).attr("url");
      e.stopPropagation();
      return false;
    }
  });
});
