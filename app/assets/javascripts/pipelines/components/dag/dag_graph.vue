<script>
import * as d3 from 'd3';
import { uniqueId } from 'lodash';
import { PARSE_FAILURE } from './constants';

import { createSankey, getMaxNodes, removeOrphanNodes } from './utils';

export default {
  viewOptions: {
    baseHeight: 300,
    baseWidth: 1000,
    minNodeHeight: 60,
    nodeWidth: 16,
    nodePadding: 25,
    paddingForLabels: 100,
    labelMargin: 8,

    // can plausibly applied through CSS instead, TBD
    baseOpacity: 0.8,
    highlightIn: 1,
    highlightOut: 0.2,

    containerClasses: ['dag-graph-container', 'gl-display-flex', 'gl-flex-direction-column'].join(
      ' ',
    ),
  },
  gitLabColorRotation: [
    '#e17223',
    '#83ab4a',
    '#5772ff',
    '#b24800',
    '#25d2d2',
    '#006887',
    '#487900',
    '#d84280',
    '#3547de',
    '#6f3500',
    '#006887',
    '#275600',
    '#b31756',
  ],
  props: {
    graphData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      color: () => {},
      width: 0,
      height: 0,
    };
  },
  mounted() {
    let countedAndTransformed;

    try {
      countedAndTransformed = this.transformData(this.graphData);
    } catch {
      this.$emit('onFailure', PARSE_FAILURE);
      return;
    }

    this.drawGraph(countedAndTransformed);
  },
  methods: {
    addSvg() {
      return d3
        .select('.dag-graph-container')
        .append('svg')
        .attr('viewBox', [0, 0, this.width, this.height])
        .attr('width', this.width)
        .attr('height', this.height);
    },

    appendLinks(link) {
      return (
        link
          .append('path')
          .attr('d', this.createLinkPath)
          .attr('stroke', ({ gradId }) => `url(#${gradId})`)
          .style('stroke-linejoin', 'round')
          // minus two to account for the rounded nodes
          .attr('stroke-width', ({ width }) => Math.max(1, width - 2))
          .attr('clip-path', ({ clipId }) => `url(#${clipId})`)
      );
    },

    appendLabelAsForeignObject(d, i, n) {
      const currentNode = n[i];
      const { height, wrapperWidth, width, x, y, textAlign } = this.labelPosition(d);

      const labelClasses = [
        'gl-display-flex',
        'gl-pointer-events-none',
        'gl-flex-direction-column',
        'gl-justify-content-center',
        'gl-overflow-wrap-break',
      ].join(' ');

      return (
        d3
          .select(currentNode)
          .attr('requiredFeatures', 'http://www.w3.org/TR/SVG11/feature#Extensibility')
          .attr('height', height)
          /*
            items with a 'max-content' width will have a wrapperWidth for the foreignObject
          */
          .attr('width', wrapperWidth || width)
          .attr('x', x)
          .attr('y', y)
          .classed('gl-overflow-visible', true)
          .append('xhtml:div')
          .classed(labelClasses, true)
          .style('height', height)
          .style('width', width)
          .style('text-align', textAlign)
          .text(({ name }) => name)
      );
    },

    createAndAssignId(datum, field, modifier = '') {
      const id = uniqueId(modifier);
      /* eslint-disable-next-line no-param-reassign */
      datum[field] = id;
      return id;
    },

    createClip(link) {
      /*
        Because large link values can overrun their box, we create a clip path
        to trim off the excess in charts that have few nodes per column and are
        therefore tall.

        The box is created by
          M: moving to outside midpoint of the source node
          V: drawing a vertical line to maximum of the bottom link edge or
            the lowest edge of the node (can be d.y0 or d.y1 depending on the link's path)
          H: drawing a horizontal line to the outside edge of the destination node
          V: drawing a vertical line back up to the minimum of the top link edge or
            the highest edge of the node (can be d.y0 or d.y1 depending on the link's path)
          H: drawing a horizontal line back to the outside edge of the source node
          Z: closing the path, back to the start point
      */

      const clip = ({ y0, y1, source, target, width }) => {
        const bottomLinkEdge = Math.max(y1, y0) + width / 2;
        const topLinkEdge = Math.min(y0, y1) - width / 2;

        /* eslint-disable @gitlab/require-i18n-strings */
        return `
          M${source.x0}, ${y1}
          V${Math.max(bottomLinkEdge, y0, y1)}
          H${target.x1}
          V${Math.min(topLinkEdge, y0, y1)}
          H${source.x0}
          Z`;
        /* eslint-enable @gitlab/require-i18n-strings */
      };

      return link
        .append('clipPath')
        .attr('id', d => {
          return this.createAndAssignId(d, 'clipId', 'dag-clip');
        })
        .append('path')
        .attr('d', clip);
    },

    createGradient(link) {
      const gradient = link
        .append('linearGradient')
        .attr('id', d => {
          return this.createAndAssignId(d, 'gradId', 'dag-grad');
        })
        .attr('gradientUnits', 'userSpaceOnUse')
        .attr('x1', ({ source }) => source.x1)
        .attr('x2', ({ target }) => target.x0);

      gradient
        .append('stop')
        .attr('offset', '0%')
        .attr('stop-color', ({ source }) => this.color(source));

      gradient
        .append('stop')
        .attr('offset', '100%')
        .attr('stop-color', ({ target }) => this.color(target));
    },

    createLinkPath({ y0, y1, source, target, width }, idx) {
      const { nodeWidth } = this.$options.viewOptions;

      /*
        Creates a series of staggered midpoints for the link paths, so they
        don't run along one channel and can be distinguished.

        First, get a point staggered by index and link width, modulated by the link box
        to find a point roughly between the nodes.

        Then offset it by nodeWidth, so it doesn't run under any nodes at the left.

        Determine where it would overlap at the right.

        Finally, select the leftmost of these options:
          - offset from the source node based on index + fudge;
          - a fuzzy offset from the right node, using Math.random adds a little blur
          - a hard offset from the end node, if random pushes it over

        Then draw a line from the start node to the bottom-most point of the midline
        up to the topmost point in that line and then to the middle of the end node
      */

      const xValRaw = source.x1 + (((idx + 1) * width) % (target.x1 - source.x0));
      const xValMin = xValRaw + nodeWidth;
      const overlapPoint = source.x1 + (target.x0 - source.x1);
      const xValMax = overlapPoint - nodeWidth * 1.4;

      const midPointX = Math.min(xValMin, target.x0 - nodeWidth * 4 * Math.random(), xValMax);

      return d3.line()([
        [(source.x0 + source.x1) / 2, y0],
        [midPointX, y0],
        [midPointX, y1],
        [(target.x0 + target.x1) / 2, y1],
      ]);
    },

    createLinks(svg, linksData) {
      const link = this.generateLinks(svg, linksData);
      this.createGradient(link);
      this.createClip(link);
      this.appendLinks(link);
    },

    createNodes(svg, nodeData) {
      this.generateNodes(svg, nodeData);
      this.labelNodes(svg, nodeData);
    },

    drawGraph({ maxNodesPerLayer, linksAndNodes }) {
      const {
        baseWidth,
        baseHeight,
        minNodeHeight,
        nodeWidth,
        nodePadding,
        paddingForLabels,
      } = this.$options.viewOptions;

      this.width = baseWidth;
      this.height = baseHeight + maxNodesPerLayer * minNodeHeight;
      this.color = this.initColors();

      const { links, nodes } = createSankey({
        width: this.width,
        height: this.height,
        nodeWidth,
        nodePadding,
        paddingForLabels,
      })(linksAndNodes);

      const svg = this.addSvg();
      this.createLinks(svg, links);
      this.createNodes(svg, nodes);
    },

    generateLinks(svg, linksData) {
      const linkContainerName = 'dag-link';

      return svg
        .append('g')
        .attr('fill', 'none')
        .attr('stroke-opacity', this.$options.viewOptions.baseOpacity)
        .selectAll(`.${linkContainerName}`)
        .data(linksData)
        .enter()
        .append('g')
        .attr('id', d => {
          return this.createAndAssignId(d, 'uid', linkContainerName);
        })
        .classed(`${linkContainerName} gl-cursor-pointer`, true);
    },

    generateNodes(svg, nodeData) {
      const nodeContainerName = 'dag-node';
      const { nodeWidth } = this.$options.viewOptions;

      return svg
        .append('g')
        .selectAll(`.${nodeContainerName}`)
        .data(nodeData)
        .enter()
        .append('line')
        .classed(`${nodeContainerName} gl-cursor-pointer`, true)
        .attr('id', d => {
          return this.createAndAssignId(d, 'uid', nodeContainerName);
        })
        .attr('stroke', this.color)
        .attr('stroke-width', nodeWidth)
        .attr('stroke-linecap', 'round')
        .attr('x1', d => Math.floor((d.x1 + d.x0) / 2))
        .attr('x2', d => Math.floor((d.x1 + d.x0) / 2))
        .attr('y1', d => d.y0 + 4)
        .attr('y2', d => d.y1 - 4);
    },

    labelNodes(svg, nodeData) {
      return svg
        .append('g')
        .classed('gl-font-sm', true)
        .selectAll('text')
        .data(nodeData)
        .enter()
        .append('foreignObject')
        .each(this.appendLabelAsForeignObject);
    },

    initColors() {
      const colorFn = d3.scaleOrdinal(this.$options.gitLabColorRotation);
      return ({ name }) => colorFn(name);
    },

    labelPosition({ x0, x1, y0, y1 }) {
      const { paddingForLabels, labelMargin, nodePadding } = this.$options.viewOptions;

      const firstCol = x0 <= paddingForLabels;
      const lastCol = x1 >= this.width - paddingForLabels;

      if (firstCol) {
        return {
          x: 0 + labelMargin,
          y: y0,
          height: `${y1 - y0}px`,
          width: paddingForLabels - 2 * labelMargin,
          textAlign: 'right',
        };
      }

      if (lastCol) {
        return {
          x: this.width - paddingForLabels + labelMargin,
          y: y0,
          height: `${y1 - y0}px`,
          width: paddingForLabels - 2 * labelMargin,
          textAlign: 'left',
        };
      }

      return {
        x: (x1 + x0) / 2,
        y: y0 - nodePadding,
        height: `${nodePadding}px`,
        width: 'max-content',
        wrapperWidth: paddingForLabels - 2 * labelMargin,
        textAlign: x0 < this.width / 2 ? 'left' : 'right',
      };
    },

    transformData(parsed) {
      const baseLayout = createSankey()(parsed);
      const cleanedNodes = removeOrphanNodes(baseLayout.nodes);
      const maxNodesPerLayer = getMaxNodes(cleanedNodes);

      return {
        maxNodesPerLayer,
        linksAndNodes: {
          links: parsed.links,
          nodes: cleanedNodes,
        },
      };
    },
  },
};
</script>
<template>
  <div :class="$options.viewOptions.containerClasses" data-testid="dag-graph-container">
    <!-- graph goes here -->
  </div>
</template>
