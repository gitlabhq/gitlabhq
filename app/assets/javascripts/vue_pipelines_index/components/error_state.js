import pipelinesErrorStateSVG from 'empty_states/icons/_pipelines_failed.svg';

export default {
  data() {
    return {
      pipelinesErrorStateSVG,
    };
  },

  template: `
  <div class="row empty-state">
    <div class="col-xs-12 pull-right">
      <div class="svg-content">
        ${pipelinesErrorStateSVG}
      </div>
    </div>

    <div class="col-xs-12 center">
      <div class="text-content">
        <h4>The API failed to fetch the pipelines.</h4>
      </div>
    </div>
  </div>
  `,
};
