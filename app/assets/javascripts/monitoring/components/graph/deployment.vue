<script>
  export default {
    props: {
      deploymentData: {
        type: Array,
        required: true,
      },
      graphHeight: {
        type: Number,
        required: true,
      },
      graphHeightOffset: {
        type: Number,
        required: true,
      },
    },

    computed: {
      calculatedHeight() {
        return this.graphHeight - this.graphHeightOffset;
      },
    },

    methods: {
      transformDeploymentGroup(deployment) {
        return `translate(${Math.floor(deployment.xPos) - 5}, 20)`;
      },
    },
  };
</script>
<template>
  <g class="deploy-info">
    <g
      v-for="(deployment, index) in deploymentData"
      :key="index"
      :transform="transformDeploymentGroup(deployment)">
      <rect
        x="0"
        y="0"
        :height="calculatedHeight"
        width="3"
        fill="url(#shadow-gradient)"
      />
      <line
        class="deployment-line"
        x1="0"
        y1="0"
        x2="0"
        :y2="calculatedHeight"
        stroke="#000"
      />
    </g>
    <svg
      height="0"
      width="0"
    >
      <defs>
        <linearGradient
          id="shadow-gradient"
        >
          <stop
            offset="0%"
            stop-color="#000"
            stop-opacity="0.4"
          />
          <stop
            offset="100%"
            stop-color="#000"
            stop-opacity="0"
          />
        </linearGradient>
      </defs>
    </svg>
  </g>
</template>
