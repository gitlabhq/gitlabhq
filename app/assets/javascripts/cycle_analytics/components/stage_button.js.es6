((global) => {

  global.cycleAnalytics = global.cycleAnalytics || {};

  global.cycleAnalytics.StageButton = Vue.extend({
    props: {
      stage: Object,
      onStageClick: Function
    },
    computed: {
      classObject() {
        return {
          'active': this.stage.active
        }
      }
    },
    methods: {
      onClick(stage) {
        this.onStageClick(stage);
      }
    }
  });


})(window.gl || (window.gl = {}));

