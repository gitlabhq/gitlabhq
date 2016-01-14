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
          var s = '';
          for(s in data) {
            store.state[s] = data[s]; 
          }
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

      methods: {
        closeClicked: function() {
          mrService.changeState('close');
        },

        reopenClicked: function() {
          mrService.changeState('reopen');
        }
      }
    }),

    mrStateBox = new Vue({
      el: '#mr-state-box',
      data: {
        state: store.state
      },

      methods: {

      }
    });
  } 

  return {
    init: init
  }
};