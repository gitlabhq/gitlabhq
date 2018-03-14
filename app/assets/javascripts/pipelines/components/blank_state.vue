<script>
  export default {
    name: 'PipelinesSvgState',
    props: {
      svgPath: {
        type: String,
        required: true,
      },

      message: {
        type: String,
        required: true,
      },
    },
  };
</script>

<template>
  <div class="row empty-state">
    <div class="col-xs-12">
      <div class="svg-content">
        <img :src="svgPath" />
      </div>
    </div>

    <div class="col-xs-12 text-center">
      <div class="text-content">
        <h4>{{ message }}</h4>
      </div>
    </div>
  </div>
</template>
