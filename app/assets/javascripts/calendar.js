var options = {month: "short", day: "numeric"};
function calOnClick(data, date, nb)
  {
    $("#onClick-placeholder").hide();

    $("#onClick-placeholder").html("<span class='onClicksecond'><b>" + (nb === null ? "no" : nb) + "</b><span class='commit_date'> commit" + ((nb!=1)?'s':'') + " " + date.toLocaleDateString("en-US",options) + "</span><hr class='onclick_hr'></span>");

    $.each(data, function (key, data) {
      $.each(data, function (index, data) {
        $("#onClick-placeholder").append("Pushed <b>" + (data === null ? "no" : data) + " commit" + ((data!=1)?'s':'') +"</b> to <a href='/" + index + "'>" + index + "</a><hr class='onclick_hr'>")
      })
    })
  };

var cal = new CalHeatMap();
  cal.init({
    itemName: ["commit"],
    data: CommitsCalendar.timestamps,
    start: new Date(CommitsCalendar.starting_year, CommitsCalendar.starting_month),
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
        url: CommitsCalendar.path,
        data: {date: date},
        dataType: 'json',
        success: function(data) {
          $("#loading-commits").fadeIn();
          calOnClick(data, date, count)
          setTimeout(function() {$("#onClick-placeholder").fadeIn(500);}, 400);
          setTimeout(function() {$("#loading-commits").hide();}, 400);
        },
        error: function(data) {
        }
      }) 
      }
});
