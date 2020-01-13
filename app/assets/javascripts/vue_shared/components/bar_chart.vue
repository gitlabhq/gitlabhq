<script>
import * as d3 from 'd3';
import tooltip from '../directives/tooltip';
import Icon from './icon.vue';
import SvgGradient from './svg_gradient.vue';
import {
  GRADIENT_COLORS,
  GRADIENT_OPACITY,
  INVERSE_GRADIENT_COLORS,
  INVERSE_GRADIENT_OPACITY,
} from './bar_chart_constants';

/**
 * Renders a bar chart that can be dragged(scrolled) when the number
 * of elements to renders surpasses that of the available viewport space
 * while keeping even padding and a width of 24px (customizable)
 *
 * It can render data with the following format:
 * graphData: [{
 *   name: 'element' // x domain data
 *   value: 1 // y domain data
 * }]
 *
 * Used in:
 * - Contribution analytics - all of the rows describing pushes, merge requests and issues
 */

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    SvgGradient,
  },
  props: {
    graphData: {
      type: Array,
      required: true,
    },
    barWidth: {
      type: Number,
      required: false,
      default: 24,
    },
    yAxisLabel: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      minX: -40,
      minY: 0,
      vbWidth: 0,
      vbHeight: 0,
      vpWidth: 0,
      vpHeight: 200,
      preserveAspectRatioType: 'xMidYMin meet',
      containerMargin: {
        leftRight: 30,
      },
      viewBoxMargin: {
        topBottom: 100,
      },
      panX: 0,
      xScale: {},
      yScale: {},
      zoom: {},
      bars: {},
      xGraphRange: 0,
      isLoading: true,
      paddingThreshold: 50,
      showScrollIndicator: false,
      showLeftScrollIndicator: false,
      isGrabbed: false,
      isPanAvailable: false,
      gradientColors: GRADIENT_COLORS,
      gradientOpacity: GRADIENT_OPACITY,
      inverseGradientColors: INVERSE_GRADIENT_COLORS,
      inverseGradientOpacity: INVERSE_GRADIENT_OPACITY,
      maxTextWidth: 72,
      rectYAxisLabelDims: {},
      xAxisTextElements: {},
      yAxisRectTransformPadding: 20,
      yAxisTextTransformPadding: 10,
      yAxisTextRotation: 90,
    };
  },
  computed: {
    svgViewBox() {
      return `${this.minX} ${this.minY} ${this.vbWidth} ${this.vbHeight}`;
    },
    xAxisLocation() {
      return `translate(${this.panX}, ${this.vbHeight})`;
    },
    barTranslationTransform() {
      return `translate(${this.panX}, 0)`;
    },
    scrollIndicatorTransform() {
      return `translate(${this.vbWidth - 80}, 0)`;
    },
    activateGrabCursor() {
      return {
        'svg-graph-container-with-grab': this.isPanAvailable,
        'svg-graph-container-grabbed': this.isPanAvailable && this.isGrabbed,
      };
    },
    yAxisLabelRectTransform() {
      const rectWidth =
        this.rectYAxisLabelDims.height != null ? this.rectYAxisLabelDims.height / 2 : 0;
      const yCoord = this.vbHeight / 2 - rectWidth;

      return `translate(${this.minX - this.yAxisRectTransformPadding}, ${yCoord})`;
    },
    yAxisLabelTextTransform() {
      const rectWidth =
        this.rectYAxisLabelDims.height != null ? this.rectYAxisLabelDims.height / 2 : 0;
      const yCoord = this.vbHeight / 2 + rectWidth - 5;

      return `translate(${this.minX + this.yAxisTextTransformPadding}, ${yCoord}) rotate(-${
        this.yAxisTextRotation
      })`;
    },
  },
  mounted() {
    this.draw();
  },
  methods: {
    draw() {
      // update viewport
      this.vpWidth = this.$refs.svgContainer.clientWidth - this.containerMargin.leftRight;
      // update viewbox
      this.vbWidth = this.vpWidth;
      this.vbHeight = this.vpHeight - this.viewBoxMargin.topBottom;
      let padding = 0;
      if (this.graphData.length * this.barWidth > this.vbWidth) {
        this.xGraphRange = this.graphData.length * this.barWidth;
        padding = this.calculatePadding(this.barWidth);
        this.showScrollIndicator = true;
        this.isPanAvailable = true;
      } else {
        this.xGraphRange = this.vbWidth - Math.abs(this.minX);
      }

      this.xScale = d3
        .scaleBand()
        .range([0, this.xGraphRange])
        .round(true)
        .paddingInner(padding);
      this.yScale = d3.scaleLinear().rangeRound([this.vbHeight, 0]);

      this.xScale.domain(this.graphData.map(d => d.name));
      /*
      If we have all-zero graph we want graph to center 0 on axis and not to draw
      any kind of ticks on Y axis. Infinity allows us to do that.

      See https://gitlab.com/gitlab-org/gitlab/merge_requests/20627#note_251484582
      for detailed explanation
      */
      this.yScale.domain([0, d3.max(this.graphData.map(d => d.value)) || Infinity]);

      // Zoom/Panning Function
      this.zoom = d3
        .zoom()
        .translateExtent([[0, 0], [this.xGraphRange, this.vbHeight]])
        .on('zoom', this.panGraph)
        .on('end', this.removeGrabStyling);

      const xAxis = d3.axisBottom().scale(this.xScale);

      const yAxis = d3
        .axisLeft()
        .scale(this.yScale)
        .ticks(4);

      const renderedXAxis = d3
        .select(this.$refs.baseSvg)
        .select('.x-axis')
        .call(xAxis);

      this.xAxisTextElements = this.$refs.xAxis.querySelectorAll('text');

      renderedXAxis.select('.domain').remove();

      renderedXAxis
        .selectAll('text')
        .style('text-anchor', 'end')
        .attr('dx', '-.3em')
        .attr('dy', '-.95em')
        .attr('class', 'tick-text')
        .attr('transform', 'rotate(-90)');

      renderedXAxis.selectAll('line').remove();

      const { maxTextWidth } = this;
      renderedXAxis.selectAll('text').each(function formatText() {
        const axisText = d3.select(this);
        let textLength = axisText.node().getComputedTextLength();
        let textContent = axisText.text();
        while (textLength > maxTextWidth && textContent.length > 0) {
          textContent = textContent.slice(0, -1);
          axisText.text(`${textContent}...`);
          textLength = axisText.node().getComputedTextLength();
        }
      });

      const width = this.vbWidth;

      const renderedYAxis = d3
        .select(this.$refs.baseSvg)
        .select('.y-axis')
        .call(yAxis);

      renderedYAxis.selectAll('.tick').each(function createTickLines(d, i) {
        if (i > 0) {
          d3.select(this)
            .select('line')
            .attr('x2', width)
            .attr('class', 'axis-tick');
        }
      });

      // Add the panning capabilities
      if (this.isPanAvailable) {
        d3.select(this.$refs.baseSvg)
          .call(this.zoom)
          .on('wheel.zoom', null); // This disables the pan of the graph with the scroll of the mouse wheel
      }

      this.isLoading = false;
      // Update the yAxisLabel coordinates
      const labelDims = this.$refs.yAxisLabel.getBBox();
      this.rectYAxisLabelDims = {
        height: labelDims.width + 10,
      };
    },
    panGraph() {
      const allowedRightScroll = this.xGraphRange - this.vbWidth - this.paddingThreshold;
      const graphMaxPan = Math.abs(d3.event.transform.x) < allowedRightScroll;
      this.isGrabbed = true;
      this.panX = d3.event.transform.x;

      if (d3.event.transform.x === 0) {
        this.showLeftScrollIndicator = false;
      } else {
        this.showLeftScrollIndicator = true;
        this.showScrollIndicator = true;
      }

      if (!graphMaxPan) {
        this.panX = -1 * (this.xGraphRange - this.vbWidth + this.paddingThreshold);
        this.showScrollIndicator = false;
      }
    },
    setTooltipTitle(data) {
      return data !== null ? `${data.name}: ${data.value}` : '';
    },
    calculatePadding(desiredBarWidth) {
      const widthWithMargin = this.vbWidth - Math.abs(this.minX);
      const dividend = widthWithMargin - this.graphData.length * desiredBarWidth;
      const divisor = widthWithMargin - desiredBarWidth;

      return dividend / divisor;
    },
    removeGrabStyling() {
      this.isGrabbed = false;
    },
    barHoveredIn(index) {
      this.xAxisTextElements[index].classList.add('x-axis-text');
    },
    barHoveredOut(index) {
      this.xAxisTextElements[index].classList.remove('x-axis-text');
    },
  },
};
</script>
<template>
  <div ref="svgContainer" :class="activateGrabCursor" class="svg-graph-container">
    <svg
      ref="baseSvg"
      class="svg-graph overflow-visible pt-5"
      :width="vpWidth"
      :height="vpHeight"
      :viewBox="svgViewBox"
      :preserveAspectRatio="preserveAspectRatioType"
    >
      <g ref="xAxis" :transform="xAxisLocation" class="x-axis" />
      <g v-if="!isLoading">
        <template v-for="(data, index) in graphData">
          <rect
            :key="index"
            v-tooltip
            :width="xScale.bandwidth()"
            :x="xScale(data.name)"
            :y="yScale(data.value)"
            :height="vbHeight - yScale(data.value)"
            :transform="barTranslationTransform"
            :title="setTooltipTitle(data)"
            class="bar-rect"
            data-placement="top"
            @mouseover="barHoveredIn(index)"
            @mouseout="barHoveredOut(index)"
          />
        </template>
      </g>
      <rect :height="vbHeight + 100" transform="translate(-100, -5)" width="100" fill="#fff" />
      <g class="y-axis-label">
        <line :x1="0" :x2="0" :y1="0" :y2="vbHeight" transform="translate(-35, 0)" stroke="black" />
        <!-- Get text length and change the height of this rect accordingly -->
        <rect
          :height="rectYAxisLabelDims.height"
          :transform="yAxisLabelRectTransform"
          :width="30"
          fill="#fff"
        />
        <text ref="yAxisLabel" :transform="yAxisLabelTextTransform">{{ yAxisLabel }}</text>
      </g>
      <g class="y-axis" />
      <g v-if="showScrollIndicator">
        <rect
          :height="vbHeight + 100"
          :transform="`translate(${vpWidth - 60}, -5)`"
          width="40"
          fill="#fff"
        />
        <icon
          :x="vpWidth - 50"
          :y="vbHeight / 2"
          :width="14"
          :height="14"
          name="chevron-right"
          class="animate-flicker"
        />
      </g>
      <!-- The line that shows up when the data elements surpass the available width -->
      <g v-if="showScrollIndicator" :transform="scrollIndicatorTransform">
        <rect :height="vbHeight" x="0" y="0" width="20" fill="url(#shadow-gradient)" />
      </g>
      <!-- Left scroll indicator -->
      <g v-if="showLeftScrollIndicator" transform="translate(0, 0)">
        <rect :height="vbHeight" x="0" y="0" width="20" fill="url(#left-shadow-gradient)" />
      </g>
      <svg-gradient
        :colors="gradientColors"
        :opacity="gradientOpacity"
        identifier-name="shadow-gradient"
      />
      <svg-gradient
        :colors="inverseGradientColors"
        :opacity="inverseGradientOpacity"
        identifier-name="left-shadow-gradient"
      />
    </svg>
  </div>
</template>
