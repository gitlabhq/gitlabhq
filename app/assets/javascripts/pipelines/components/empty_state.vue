<script>
  export default {
    props: {
      helpPagePath: {
        type: String,
        required: true,
      },
      emptyStateSvgPath: {
        type: String,
        required: true,
      },
    },
  };
</script>
<template>
  <div class="row empty-state js-empty-state">
    <div class="col-xs-12">
      <div class="svg-content svg-250">
        <img :src="emptyStateSvgPath" />
      </div>
    </div>

    <div class="col-xs-12">
      <div class="text-content">
        <h4 class="text-center">
          Build with confidence
        </h4>
        <p>
          Continous Integration can help catch bugs by running your tests automatically,
          while Continuous Deployment can help you deliver code to your product environment.
        </p>
        <div class="text-center">
          <a
            :href="helpPagePath"
            class="btn btn-info"
            >
            Get started with Pipelines
          </a>
        </div>
      </div>
    </div>
  </div>
</template>
