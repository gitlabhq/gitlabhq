var MR = function(){

  var store = {state:{}};

  var mrService = {
    changeState: function(newState) {
      mergeFailMessage = 'Unable to update this merge request at this time.'
      $.ajax({
        type: 'PUT',
        url: store.state[newState+'URL'],
        error: function(jqXHR, textStatus, errorThrown) {
          console.log('error',errorThrown)
          return new Flash(mergeFailMessage, 'alert');
        },
        success: function(data, textStatus, jqXHR) {
          console.log("data",data);
        }
      });
    }
  };

  var init = function(data){
    store.state = data;
    var mrHeader = new Vue({
      el: '#merge-request-header',
      data: {
        state: store.state
      },
      created: function() {},

      methods: {
        closeClicked: function() {
          mrService.changeState('close');
        },

        reopenClicked: function() {
          mrService.changeState('reopen');
        }
      }
    });
  } 

  return {
    init: init
  }
};