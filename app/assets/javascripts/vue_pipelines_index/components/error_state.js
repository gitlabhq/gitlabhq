import pipelinesErrorStateSVG from 'empty_states/icons/_pipelines_failed.svg';

export default {
  template: `
    <div class="row empty-state js-pipelines-error-state">
      <div class="col-xs-12">
        <div class="svg-content">
          ${pipelinesErrorStateSVG}
        </div>
      </div>

      <div class="col-xs-12 text-center">
        <div class="text-content">
          <h4>The API failed to fetch the pipelines.</h4>
        </div>
      </div>
    </div>
  `,
};
