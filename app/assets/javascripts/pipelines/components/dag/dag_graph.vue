<script>
import * as d3 from 'd3';
import { uniqueId } from 'lodash';
import { LINK_SELECTOR, NODE_SELECTOR, ADD_NOTE, REMOVE_NOTE, REPLACE_NOTES } from './constants';
import {
  currentIsLive,
  getLiveLinksAsDict,
  highlightLinks,
  restoreLinks,
  toggleLinkHighlight,
  togglePathHighlights,
} from './interactions';
import { getMaxNodes, removeOrphanNodes } from '../parsing_utils';
import { calculateClip, createLinkPath, createSankey, labelPosition } from './drawing_utils';
import { PARSE_FAILURE } from '../../constants';

export default {
  viewOptions: {
    baseHeight: 300,
    baseWidth: 1000,
    minNodeHeight: 60,
    nodeWidth: 16,
    nodePadding: 25,
    paddingForLabels: 100,
    labelMargin: 8,

    baseOpacity: 0.8,
    containerClasses: ['dag-graph-container', 'gl-display-flex', 'gl-flex-direction-column'].join(
      ' ',
    ),
    hoverFadeClasses: [
      'gl-cursor-pointer',
      'gl-transition-duration-slow',
      'gl-transition-timing-function-ease',
    ].join(' '),
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
      height: 0,
      width: 0,
    };
  },
  mounted() {
    let countedAndTransformed;

    try {
      countedAndTransformed = this.transformData(this.graphData);
    } catch {
      this.$emit('on-failure', PARSE_FAILURE);
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

    appendLinkInteractions(link) {
      const { baseOpacity } = this.$options.viewOptions;
      return link
        .on('mouseover', (d, idx, collection) => {
          if (currentIsLive(idx, collection)) {
            return;
          }
          this.$emit('update-annotation', { type: ADD_NOTE, data: d });
          highlightLinks(d, idx, collection);
        })
        .on('mouseout', (d, idx, collection) => {
          if (currentIsLive(idx, collection)) {
            return;
          }
          this.$emit('update-annotation', { type: REMOVE_NOTE, data: d });
          restoreLinks(baseOpacity);
        })
        .on('click', (d, idx, collection) => {
          toggleLinkHighlight(baseOpacity, d, idx, collection);
          this.$emit('update-annotation', { type: REPLACE_NOTES, data: getLiveLinksAsDict() });
        });
    },

    appendNodeInteractions(node) {
      return node.on('click', (d, idx, collection) => {
        togglePathHighlights(this.$options.viewOptions.baseOpacity, d, idx, collection);
        this.$emit('update-annotation', { type: REPLACE_NOTES, data: getLiveLinksAsDict() });
      });
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
      const links = this.generateLinks(svg, linksData);
      this.createGradient(links);
      this.createClip(links);
      this.appendLinks(links);
      this.appendLinkInteractions(links);
    },

    createNodes(svg, nodeData) {
      const nodes = this.generateNodes(svg, nodeData);
      this.labelNodes(svg, nodeData);
      this.appendNodeInteractions(nodes);
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
      return svg
        .append('g')
        .attr('fill', 'none')
        .attr('stroke-opacity', this.$options.viewOptions.baseOpacity)
        .selectAll(`.${LINK_SELECTOR}`)
        .data(linksData)
        .enter()
        .append('g')
        .attr('id', d => {
          return this.createAndAssignId(d, 'uid', LINK_SELECTOR);
        })
        .classed(
          `${LINK_SELECTOR} gl-transition-property-stroke-opacity ${this.$options.viewOptions.hoverFadeClasses}`,
          true,
        );
    },

    generateNodes(svg, nodeData) {
      const { nodeWidth } = this.$options.viewOptions;

      return svg
        .append('g')
        .selectAll(`.${NODE_SELECTOR}`)
        .data(nodeData)
        .enter()
        .append('line')
        .classed(
          `${NODE_SELECTOR} gl-transition-property-stroke ${this.$options.viewOptions.hoverFadeClasses}`,
          true,
        )
        .attr('id', d => {
          return this.createAndAssignId(d, 'uid', NODE_SELECTOR);
        })
        .attr('stroke', d => {
          const color = this.color(d);
          /* eslint-disable-next-line no-param-reassign */
          d.color = color;
          return color;
        })
        .attr('stroke-width', nodeWidth)
        .attr('stroke-linecap', 'round')
        .attr('x1', d => Math.floor((d.x1 + d.x0) / 2))
        .attr('x2', d => Math.floor((d.x1 + d.x0) / 2))
        .attr('y1', d => d.y0 + 4)
        .attr('y2', d => d.y1 - 4);
    },

    initColors() {
      const colorFn = d3.scaleOrdinal(this.$options.gitLabColorRotation);
      return ({ name }) => colorFn(name);
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
