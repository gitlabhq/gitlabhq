var MR = function(){

  var store = {state:{}};

  var mrService = {
    changeState: function(newState) {
      var mergeFailMessage = 'Unable to update this merge request at this time.'
      $.ajax({
        type: 'PUT',
        url: store.state[newState+'URL'],
        error: function(jqXHR, textStatus, errorThrown) {
          console.log('error',errorThrown);
          return new Flash(mergeFailMessage, 'alert');
        },
        success: function(data, textStatus, jqXHR) {
          var s = '';
          for(s in data) {
            store.state[s] = data[s]; 
          }
        }
      });
    },

    deleteBranch: function() {
      var branchDeleteFailMessage = 'Unable to update this merge request at this time.'
      $.ajax({
        type: 'DELETE',
        url: store.state.remove_source_branch_url,
        error: function(jqXHR, textStatus, errorThrown) {
          console.log('error', errorThrown);
          return new Flash(branchDeleteFailMessage);
        },
        success: function(data, textStatus, jqXHR) {
          var s = '';
          console.log('data',data);
          for(s in data) {
            store.state[s] = data[s];
          }
        }
      })
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
        deleteBranchClicked: function() {
          mrService.deleteBranch();
        }
      }
    });
  } 

  return {
    init: init
  }
};