/**
 * Init dashboard page
 *
 */
function dashboardPage(){ 
  $(".event_filter_link").bind('click',(function(){
    enableFilter(this.id);
  }));
}

function enableFilter(sender_id){
  var event_filters = $.cookie('event_filter');
  var filter = sender_id.split('_')[0];
  if (!event_filters) {
    event_filters = new Array();
  } else {
    event_filters = event_filters.split(',');
  }
  var index = event_filters.indexOf(filter);
  if (index == -1) {
    event_filters.push(filter);
  } else {
    event_filters.splice(index, 1);
  }
  $.cookie('event_filter', event_filters.join(','));
};

