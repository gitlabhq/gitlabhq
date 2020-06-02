<script>
import * as d3 from 'd3';
import { uniqueId } from 'lodash';
import { PARSE_FAILURE } from './constants';

import { getMaxNodes, removeOrphanNodes } from './parsing_utils';
import { calculateClip, createLinkPath, createSankey, labelPosition } from './drawing_utils';

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
          .attr('d', (d, i) => createLinkPath(d, i, this.$options.viewOptions.nodeWidth))
          .attr('stroke', ({ gradId }) => `url(#${gradId})`)
          .style('stroke-linejoin', 'round')
          // minus two to account for the rounded nodes
          .attr('stroke-width', ({ width }) => Math.max(1, width - 2))
          .attr('clip-path', ({ clipId }) => `url(#${clipId})`)
      );
    },

    appendLabelAsForeignObject(d, i, n) {
      const currentNode = n[i];
      const { height, wrapperWidth, width, x, y, textAlign } = labelPosition(d, {
        ...this.$options.viewOptions,
        width: this.width,
      });

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
      return link
        .append('clipPath')
        .attr('id', d => {
          return this.createAndAssignId(d, 'clipId', 'dag-clip');
        })
        .append('path')
        .attr('d', calculateClip);
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
