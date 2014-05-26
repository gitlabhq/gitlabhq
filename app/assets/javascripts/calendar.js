var options = {month: "short", day: "numeric"};
function myFunction(data, date, nb)
  {
    $("#onClick-placeholder").html("<span style='font-size: 17px; font-weight: 500'> COMMIT ACTIVITY</span><br /><span class ='onClickphold'>Pushed <b>" + (nb === null ? "no" : nb) + " commit" + ((nb!=1)?'s':'') + "</b> <font color='#999'>" + date.toLocaleDateString("en-US",options) + "</font><br /></span>");

    $.each(data, function (key, data) {
      console.log(key)
      $.each(data, function (index, data) {
        $("#onClick-placeholder").append("Pushed <b>" + (data === null ? "no" : data) + " commit" + ((data!=1)?'s':'') +"</b> to <b><a href='/" + index + "'>" + index + "</a><br />")
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
          console.log('success')
          console.log(data)
          myFunction(data, date, count)
        },
        error: function(data) {
          console.log('error')
          console.log(data)
        }
      }) 
      }
});