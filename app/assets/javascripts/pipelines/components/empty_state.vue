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
      <div class="svg-content">
        <img :src="emptyStateSvgPath"/>
      </div>
    </div>

    <div class="col-xs-12 text-center">
      <div class="text-content">
        <h4>Build with confidence</h4>
        <p>
          Continous Integration can help catch bugs by running your tests automatically,
          while Continuous Deployment can help you deliver code to your product environment.
        </p>
        <a :href="helpPagePath" class="btn btn-info">
          Get started with Pipelines
        </a>
      </div>
    </div>
  </div>
</template>
