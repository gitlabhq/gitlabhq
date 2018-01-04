<script>
  import { dateFormatWithName, timeFormat } from '../../utils/date_time_formatters';
  import Icon from '../../../vue_shared/components/icon.vue';

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

    components: {
      Icon,
    },

    computed: {
      calculatedHeight() {
        return this.graphHeight - this.graphHeightOffset;
      },
    },

    methods: {
      refText(d) {
        return d.tag ? d.ref : d.sha.slice(0, 8);
      },

      formatTime(deploymentTime) {
        return timeFormat(deploymentTime);
      },

      formatDate(deploymentTime) {
        return dateFormatWithName(deploymentTime);
      },

      nameDeploymentClass(deployment) {
        return `deploy-info-${deployment.id}`;
      },

      transformDeploymentGroup(deployment) {
        return `translate(${Math.floor(deployment.xPos) + 1}, 20)`;
      },

      positionFlag(deployment) {
        let xPosition = 3;
        if (deployment.xPos > (this.graphWidth - 225)) {
          xPosition = -142;
        }
        return xPosition;
      },

      svgContainerHeight(tag) {
        let svgHeight = 80;
        if (!tag) {
          svgHeight -= 20;
        }
        return svgHeight;
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
        width="134"
        :height="svgContainerHeight(deployment.tag)">
        <rect
          class="rect-text-metric deploy-info-rect rect-metric"
          x="1"
          y="1"
          rx="2"
          width="132"
          :height="svgContainerHeight(deployment.tag) - 2">
        </rect>
        <text
          class="deploy-info-text text-metric-bold"
          transform="translate(5, 2)">
          Deployed
        </text>
        <!--The date info-->
        <g transform="translate(5, 20)">
          <text class="deploy-info-text">
            {{formatDate(deployment.time)}}
          </text>
          <text 
            class="deploy-info-text text-metric-bold"
            x="62">
            {{formatTime(deployment.time)}}
          </text>
        </g>
        <line
          class="divider-line"
          x1="0"
          y1="38"
          x2="132"
          :y2="38"
          stroke="#000">
        </line>
        <!--Commit information-->
        <g transform="translate(5, 40)">
          <icon
            name="commit"
            :width="12"
            :height="12"
            :y="3">
          </icon>
          <a :xlink:href="deployment.commitUrl">
            <text
              class="deploy-info-text deploy-info-text-link"
              transform="translate(20, 2)">
              {{refText(deployment)}}
            </text>
          </a>
        </g>
        <!--Tag information-->
        <g
          transform="translate(5, 55)" 
          v-if="deployment.tag">
          <icon
            name="label"
            :width="12"
            :height="12"
            :y="5">
          </icon>
          <a :xlink:href="deployment.tagUrl">
            <text
              class="deploy-info-text deploy-info-text-link"
              transform="translate(20, 2)"
              y="2">
              {{deployment.tag}}
            </text>
          </a>
        </g>
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
