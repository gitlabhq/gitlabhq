(function(){
  window.onload = function() {
    var mrHeader = new Vue({
      el: '#merge-request-header',
      data: {
        status: $('.status-box').data('status')
      },
      created: function() {
        console.log('created');
      }
    });

    var mrServices = {

    };
  } 


})()