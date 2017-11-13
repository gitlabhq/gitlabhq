<script>
  import { dateFormat, timeFormat } from '../../utils/date_time_formatters';

  export default {
    props: {
      showDeployInfo: {
        type: Boolean,
        required: true,
      },
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
      graphWidth: {
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
      refText(d) {
        return d.tag ? d.ref : d.sha.slice(0, 6);
      },

      formatTime(deploymentTime) {
        return timeFormat(deploymentTime);
      },

      formatDate(deploymentTime) {
        return dateFormat(deploymentTime);
      },

      nameDeploymentClass(deployment) {
        return `deploy-info-${deployment.id}`;
      },

      transformDeploymentGroup(deployment) {
        return `translate(${Math.floor(deployment.xPos) + 1}, 20)`;
      },

      positionFlag(deployment) {
        let xPosition = 3;
        if (deployment.xPos > (this.graphWidth - 200)) {
          xPosition = -97;
        }
        return xPosition;
      },
    },
  };
</script>
<template>
  <g
    class="deploy-info"
    v-if="showDeployInfo">
    <g
      v-for="(deployment, index) in deploymentData"
      :key="index"
      :class="nameDeploymentClass(deployment)"
      :transform="transformDeploymentGroup(deployment)">
      <rect
        x="0"
        y="0"
        :height="calculatedHeight"
        width="3"
        fill="url(#shadow-gradient)">
      </rect>
      <line
        class="deployment-line"
        x1="0"
        y1="0"
        x2="0"
        :y2="calculatedHeight"
        stroke="#000">
      </line>
      <svg
        v-if="deployment.showDeploymentFlag"
        class="js-deploy-info-box"
        :x="positionFlag(deployment)"
        y="0"
        width="92"
        height="60">
        <rect
          class="rect-text-metric deploy-info-rect rect-metric"
          x="1"
          y="1"
          rx="2"
          width="90"
          height="58">
        </rect>
        <g
          transform="translate(5, 2)">
          <text
            class="deploy-info-text text-metric-bold">
            {{refText(deployment)}}
          </text>
        </g>
        <text
          class="deploy-info-text"
          y="18"
          transform="translate(5, 2)">
          {{formatDate(deployment.time)}}
        </text>
        <text
          class="deploy-info-text text-metric-bold"
          y="38"
          transform="translate(5, 2)">
          {{formatTime(deployment.time)}}
        </text>
      </svg>
    </g>
    <svg
      height="0"
      width="0">
      <defs>
        <linearGradient
          id="shadow-gradient">
          <stop
            offset="0%"
            stop-color="#000"
            stop-opacity="0.4">
          </stop>
          <stop
            offset="100%"
            stop-color="#000"
            stop-opacity="0">
          </stop>
        </linearGradient>
      </defs>
    </svg>
  </g>
</template>
