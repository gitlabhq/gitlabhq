var MR = function(){

  var store = {state:{}};

  var init = function(data){
    store.state = data;
    console.log('initting')
    var mrHeader = new Vue({
      el: '#merge-request-header',
      data: {
        status: store.state.status
      },
      created: function() {
        console.log('created');
      }
    });

    var mrServices = {

    };
  } 

  return {
    init: init
  }
};