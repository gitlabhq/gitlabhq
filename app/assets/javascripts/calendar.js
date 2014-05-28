var options = {month: "short", day: "numeric"};
function myFunction(data, date, nb)
  {
    $("#onClick-placeholder").hide();

    $("#onClick-placeholder").html("<span class='onClicksecond'><b>" + (nb === null ? "no" : nb) + "<font color='#999'></b> commit" + ((nb!=1)?'s':'') + " " + date.toLocaleDateString("en-US",options) + "</font><hr style='padding:0px;margin:5px 0 5px 0' /></span>");

    $.each(data, function (key, data) {
      console.log(key)
      $.each(data, function (index, data) {
        $("#onClick-placeholder").append("Pushed <b>" + (data === null ? "no" : data) + " commit" + ((data!=1)?'s':'') +"</b> to <a href='/" + index + "'>" + index + "</a><hr style='padding:0px; margin:5px 0 5px 0' />")
      })
    })
  };

var cal = new CalHeatMap();
  cal.init({
    itemName: ["commit"],
    data: window.timestamps,
    start: new Date(window.timestart_year, window.timestart_month),
    domainLabelFormat: "%b",
    id : "cal-heatmap",
    domain : "month",
    subDomain : "day",
    range : 12, 
    tooltip: true,
    domainDynamicDimension: false,
    colLimit: 4,
    label: { position: "top" },
    domainMargin: 1,
    legend: [0,1,4,7],
    legendCellPadding: 3,
    onClick: function (date, count) { 
      $.ajax({
        url: window.path,
        data: {date: date},
        dataType: 'json',
        success: function(data) {
          $("#loading-commits").fadeIn();
          console.log('success')
          console.log(data)
          myFunction(data, date, count)
          setTimeout(function() {$("#onClick-placeholder").fadeIn(500);}, 400);
          setTimeout(function() {$("#loading-commits").hide();}, 400);
        },
        error: function(data) {
          console.log('error')
          console.log(data)
        }
      }) 
      }
});