<script>
export default {
  props: {
    clustersPath: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="row empty-state js-empty-state">
    <div class="col-12">
      <div class="text-content">
        <h4 class="state-title text-center">
          {{ s__('Serverless|Getting started with serverless') }}
        </h4>
        <p class="state-description">
          {{
            s__(`Serverless| In order to start using functions as a service,
                 you must first install Knative on your Kubernetes cluster.`)
          }}

          <a :href="helpPath"> {{ __('More information') }} </a>
        </p>

        <div class="text-center">
          <a :href="clustersPath" class="btn btn-success">
            {{ s__('Serverless|Install Knative') }}
          </a>
        </div>
      </div>
    </div>
  </div>
</template>
