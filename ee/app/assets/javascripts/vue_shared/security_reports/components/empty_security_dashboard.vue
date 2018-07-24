<script>
import { s__ } from '~/locale';

export default {
  props: {
    illustrationPath: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    paragraphText: () =>
      s__(
        `SecurityDashboard|
         The security dashboard displays the latest security report.
         Use it to find and fix vulnerabilities.`,
      ),
  },
};
</script>
<template>
  <div class="row empty-state">
    <div class="col-12">
      <div class="svg-content">
        <img
          :src="illustrationPath"
        />
      </div>
    </div>
    <div class="col-12">
      <div class="text-content text-center">
        <h4>
          {{ s__('SecurityDashboard|Monitor vulnerabilities in your code') }}
        </h4>
        <p>
          {{ paragraphText }}
        </p>
        <a
          :href="helpPath"
          class="btn btn-new"
          rel="nofollow"
        >
          {{ __('Learn more') }}
        </a>
      </div>
    </div>
  </div>
</template>
