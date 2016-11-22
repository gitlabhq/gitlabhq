//= require ./due_date_select/due_date_select_bundle
((gl) => {
  $(() => {
    const $issuableSidebar = document.getElementById('issuable-sidebar-app');
    const issuableData = JSON.parse($issuableSidebar.dataset['issuable']);
    const isAdminData = Boolean($issuableSidebar.dataset['admin']);
    const issuableEndpoint = '';

    new Vue({
      el: $issuableSidebar,
      data: {
        issuable: issuableData,
        admin: isAdminData,
        endpoint: issuableEndpoint
      },
      mounted() {
        console.log('PARENT VUE INSTANCE: ', this);

        gl.IssuableResource = new gl.SubbableResource(this.endpoint);
        gl.IssuableResource.subscribe((data)=> {
          this.issuable = data;
        });
        new gl.SmartInterval({
          startingInterval: 5000,
          maxInterval: 5000,
          increaseByFactorOf: 2,
          lazyStart: false,
          callback: gl.IssuableResource.get.bind(gl.IssuableResource)
        });
      }
    });
  });
})(window.gl || (window.gl = {}));
