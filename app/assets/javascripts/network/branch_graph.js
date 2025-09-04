/* eslint-disable consistent-return */

import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { ENTER_KEY, NUMPAD_ENTER_KEY } from '~/lib/utils/keys';
import { __, sprintf } from '~/locale';
import Raphael from './raphael';

export default class BranchGraph {
  constructor(element1, options1) {
    this.element = element1;
    this.options = options1;
    this.scrollTop = this.scrollTop.bind(this);
    this.scrollBottom = this.scrollBottom.bind(this);
    this.scrollRight = this.scrollRight.bind(this);
    this.scrollLeft = this.scrollLeft.bind(this);
    this.scrollUp = this.scrollUp.bind(this);
    this.scrollDown = this.scrollDown.bind(this);
    this.scrollHandler = this.handleScroll.bind(this);
    this.preparedCommits = {};
    this.mtime = 0;
    this.mspace = 0;
    this.parents = {};
    this.colors = ['#000'];
    this.offsetX = 150;
    this.offsetY = 20;
    this.unitTime = 30;
    this.unitSpace = 10;
    this.prev_start = -1;
    this.isDestroyed = false;
    this.load();
  }

  load() {
    axios
      .get(this.options.url)
      .then(({ data }) => {
        $('.loading', this.element).hide();
        this.prepareData(data.days, data.commits);
        this.prepareLongDesc();
        this.buildGraph();
      })
      .catch(() => __('Error fetching network graph.'));
  }

  /* eslint-disable class-methods-use-this */
  prepareLongDesc() {
    const longDescTarget = document.querySelector('[data-type="figure-branch-graph"]');
    const longDescriptionText = __(
      'This graph shows commit history with branches and merges arranged from newest to oldest. Each dot represents a commit, with lines showing how code changes flow between different branches.',
    );

    if (longDescTarget) {
      longDescTarget.setAttribute('aria-label', longDescriptionText);
    }
  }

  prepareData(days, commits) {
    this.days = days;
    this.commits = commits;
    this.collectParents();
    this.graphHeight = $(this.element).height();
    this.graphWidth = $(this.element).width();
    const ch = Math.max(this.graphHeight, this.offsetY + this.unitTime * this.mtime + 150);
    const cw = Math.max(this.graphWidth, this.offsetX + this.unitSpace * this.mspace + 300);
    this.r = Raphael(this.element.get(0), cw, ch);
    this.top = this.r.set();
    this.barHeight = Math.max(this.graphHeight, this.unitTime * this.days.length + 320);
    this.commits = this.commits.reduce((acc, commit) => {
      const updatedCommit = commit;
      if (commit.id in this.parents) {
        updatedCommit.isParent = true;
      }
      acc.push(updatedCommit);
      this.preparedCommits[commit.id] = commit;
      this.markCommit(commit);
      return acc;
    }, []);
    return this.collectColors();
  }

  collectParents() {
    const ref = this.commits;
    const results = [];
    ref.forEach((c) => {
      this.mtime = Math.max(this.mtime, c.time);
      this.mspace = Math.max(this.mspace, c.space);
      const ref1 = c.parents;
      const results1 = [];
      ref1.forEach((p) => {
        this.parents[p[0]] = true;
        results1.push((this.mspace = Math.max(this.mspace, p[1])));
      });
      results.push(results1);
    });
    return results;
  }

  collectColors() {
    let k = 0;
    const results = [];
    while (k < this.mspace) {
      this.colors.push(Raphael.getColor(0.8));
      // Skipping a few colors in the spectrum to get more contrast between colors
      Raphael.getColor();
      Raphael.getColor();
      results.push((k += 1));
    }
    return results;
  }

  buildGraph() {
    let mm = 0;
    let len = 0;
    let cuday = 0;
    let cumonth = '';
    let cuyear = '';
    const { r } = this;
    r.rect(0, 0, 40, this.barHeight).attr({
      fill: '#222',
    });
    r.rect(40, 0, 30, this.barHeight).attr({
      fill: '#444',
    });
    const ref = this.days;
    for (mm = 0, len = ref.length; mm < len; mm += 1) {
      const day = ref[mm];
      if (cuday !== day[0] || cumonth !== day[1] || cuyear !== day[2]) {
        // Dates
        r.text(55, this.offsetY + this.unitTime * mm, day[0]).attr({
          font: '12px Monaco, monospace',
          fill: '#BBB',
        });
      }
      if (cumonth !== day[1] || cuyear !== day[2]) {
        // Months
        r.text(20, this.offsetY + this.unitTime * mm, day[1]).attr({
          font: '12px Monaco, monospace',
          fill: '#EEE',
        });
      }
      [cuday, cumonth, cuyear] = day;
    }
    this.renderPartialGraph();
    return this.bindEvents();
  }

  renderPartialGraph() {
    const isGraphEdge = true;
    let i = 0;
    let start = Math.floor((this.element.scrollTop() - this.offsetY) / this.unitTime) - 10;
    if (start < 0) {
      start = 0;
    }
    let end = start + 40;
    if (this.commits.length < end) {
      end = this.commits.length;
    }
    if (this.prev_start === -1 || Math.abs(this.prev_start - start) > 10 || isGraphEdge) {
      i = start;
      this.prev_start = start;
      while (i < end) {
        const commit = this.commits[i];
        i += 1;
        if (commit.hasDrawn !== true) {
          const x = this.offsetX + this.unitSpace * (this.mspace - commit.space);
          const y = this.offsetY + this.unitTime * commit.time;
          this.drawDot(x, y, commit);
          this.drawLines(x, y, commit);
          this.appendLabel(x, y, commit);
          this.appendAnchor(x, y, commit);
          commit.hasDrawn = true;
        }
      }
      return this.top.toFront();
    }
  }

  handleScroll() {
    if (this.isDestroyed) return;

    // Throttle scroll events
    if (this.scrollTimeout) return;

    // Tested with _.debounce, but the redraw was not as smooth or consistent
    this.scrollTimeout = setTimeout(() => {
      this.renderPartialGraph();
      this.scrollTimeout = null;
    }, 16); // 1000 milliseconds / 60 frames = 16.66... milliseconds per frame
  }

  bindEvents() {
    if (this.isDestroyed) return;
    this.element.on('scroll', this.scrollHandler);
    return () => this.unbindEvents();
  }

  unbindEvents() {
    if (this.element) {
      this.element.off('scroll', this.scrollHandler);
    }

    if (this.scrollTimeout) {
      clearTimeout(this.scrollTimeout);
      this.scrollTimeout = null;
    }
  }

  destroy() {
    this.isDestroyed = true;
    this.unbindEvents();

    // Clean up Raphael for GC
    if (this.r) {
      this.r.remove();
      this.r = null;
    }

    // Clean up data structures for GC
    this.preparedCommits = null;
    this.parents = null;
    this.commits = null;
    this.element = null;
    this.options = null;
  }

  removeTooltip() {
    this.top.remove(this.tooltip);
    return this.tooltip && this.tooltip.remove() && delete this.tooltip;
  }

  scrollDown() {
    this.element.scrollTop(this.element.scrollTop() + 50);
    return this.renderPartialGraph();
  }

  scrollUp() {
    this.element.scrollTop(this.element.scrollTop() - 50);
    return this.renderPartialGraph();
  }

  scrollLeft() {
    this.element.scrollLeft(this.element.scrollLeft() - 50);
    return this.renderPartialGraph();
  }

  scrollRight() {
    this.element.scrollLeft(this.element.scrollLeft() + 50);
    return this.renderPartialGraph();
  }

  scrollBottom() {
    return this.element.scrollTop(this.element.find('svg').height());
  }

  scrollTop() {
    return this.element.scrollTop(0);
  }

  /**
   * Shows a tooltip for a commit at the specified position
   * @param {Object} options - The tooltip configuration options
   * @param {number} options.x - The x-coordinate for tooltip positioning
   * @param {number} options.y - The y-coordinate for tooltip positioning
   * @param {Object} options.commit - The commit object containing commit data
   * @returns {Object} The tooltip element brought to front
   */
  showTooltip(options) {
    const { x, y, commit } = options;
    this.tooltip = this.r.commitTooltip(x + 5, y, commit);
    this.top.push(this.tooltip.insertBefore(this.node));
    return this.tooltip.toFront();
  }

  appendLabel(x, y, commit) {
    if (!commit.refs) {
      return;
    }

    const { r } = this;
    let shortrefs = commit.refs;
    // Truncate if longer than 15 chars
    if (shortrefs.length > 17) {
      shortrefs = `${shortrefs.substr(0, 15)}…`;
    }
    const text = r.text(x + 4, y, shortrefs).attr({
      'text-anchor': 'start',
      font: '10px Monaco, monospace',
      fill: '#FFF',
      title: commit.refs,
    });
    const textbox = text.getBBox();
    // Create rectangle based on the size of the textbox
    const rect = r.rect(x, y - 7, textbox.width + 5, textbox.height + 5, 4).attr({
      fill: '#000',
      'fill-opacity': 0.5,
      stroke: 'none',
    });
    // Generate the triangle right of the tag box
    r.path(['M', x - 5, y, 'L', x - 15, y - 4, 'L', x - 15, y + 4, 'Z']).attr({
      fill: '#000',
      'fill-opacity': 0.5,
      stroke: 'none',
    });
    const label = r.set(rect, text);
    label.transform(['t', -rect.getBBox().width - 15, 0]);
    // Set text to front
    return text.toFront();
  }

  appendAnchor(x, y, commit) {
    const { r, options } = this;
    const circle = r.circle(x, y, 10);

    circle.attr({
      fill: '#000',
      opacity: 0,
      cursor: 'pointer',
    });

    const { node } = circle;
    node.setAttribute('tabindex', '0');
    node.setAttribute('role', 'link');
    node.setAttribute(
      'aria-label',
      sprintf(__('%{commitMessage}, by %{authorName}. Opens in a new window.'), {
        commitMessage: commit.message.split('\n', 1)[0],
        authorName: commit.author.name || commit.authorName,
      }),
    );

    // Create a single unified event handler instead of multiple functions
    // This reduces memory overhead from multiple function closures
    const handleInteraction = (e) => {
      const { type, key, keyCode } = e;
      const normalizedEnterKey = ENTER_KEY || NUMPAD_ENTER_KEY;

      switch (type) {
        case 'focus':
        case 'mouseover':
          this.showTooltip({ x, y, commit });
          break;
        case 'blur':
        case 'mouseout':
          this.removeTooltip();
          break;
        case 'keydown':
          if (key === normalizedEnterKey || keyCode === 13) {
            visitUrl(options.commit_url.replace('%s', commit.id), true);
          }
          break;
        case 'click':
          visitUrl(options.commit_url.replace('%s', commit.id), true);
          break;
        default:
          break;
      }
    };

    // Add all event listeners using the same handler function
    // This is more memory efficient than creating separate handler functions
    const events = ['focus', 'blur', 'keydown', 'mouseover', 'mouseout', 'click'];
    for (let i = 0; i < events.length; i += 1) {
      node.addEventListener(events[i], handleInteraction);
    }
  }

  drawDot(x, y, commit) {
    const { r } = this;
    r.circle(x, y, 3).attr({
      fill: this.colors[commit.space],
      stroke: 'none',
    });

    const avatarBoxX = this.offsetX + this.unitSpace * this.mspace + 10;
    const avatarBoxY = y - 10;
    r.image(commit.author.icon, avatarBoxX, avatarBoxY, 20, 20);

    r.rect(avatarBoxX, avatarBoxY, 20, 20).attr({
      stroke: this.colors[commit.space],
      'stroke-width': 2,
    });

    return r
      .text(this.offsetX + this.unitSpace * this.mspace + 40, y, commit.message.split('\n')[0])
      .attr({
        fill: 'currentColor',
        class: 'gl-text-default',
        'text-anchor': 'start',
        font: '14px Monaco, monospace',
      });
  }

  drawLines(x, y, commit) {
    let i = 0;
    let len = 0;
    let arrow = '';
    let offset = [];
    let color = [];
    const { r } = this;
    const ref = commit.parents;
    const results = [];
    for (i = 0, len = ref.length; i < len; i += 1) {
      const parent = ref[i];
      const parentCommit = this.preparedCommits[parent[0]];
      const parentY = this.offsetY + this.unitTime * parentCommit.time;
      const parentX1 = this.offsetX + this.unitSpace * (this.mspace - parentCommit.space);
      const parentX2 = this.offsetX + this.unitSpace * (this.mspace - parent[1]);
      // Set line color
      if (parentCommit.space <= commit.space) {
        color = this.colors[commit.space];
      } else {
        color = this.colors[parentCommit.space];
      }
      // Build line shape
      if (parent[1] === commit.space) {
        offset = [0, 5];
        arrow = 'l-2,5,4,0,-2,-5,0,5';
      } else if (parent[1] < commit.space) {
        offset = [3, 3];
        arrow = 'l5,0,-2,4,-3,-4,4,2';
      } else {
        offset = [-3, 3];
        arrow = 'l-5,0,2,4,3,-4,-4,2';
      }
      // Start point
      const route = ['M', x + offset[0], y + offset[1]];
      // Add arrow if not first parent
      if (i > 0) {
        route.push(arrow);
      }
      // Circumvent if overlap
      if (commit.space !== parentCommit.space || commit.space !== parent[1]) {
        route.push('L', parentX2, y + 10, 'L', parentX2, parentY - 5);
      }
      // End point
      route.push('L', parentX1, parentY);
      results.push(
        r.path(route).attr({
          stroke: color,
          'stroke-width': 2,
        }),
      );
    }
    return results;
  }

  markCommit(commit) {
    if (commit.id === this.options.commit_id) {
      const { r } = this;
      const x = this.offsetX + this.unitSpace * (this.mspace - commit.space);
      const y = this.offsetY + this.unitTime * commit.time;
      r.path(['M', x + 5, y, 'L', x + 15, y + 4, 'L', x + 15, y - 4, 'Z']).attr({
        fill: '#000',
        'fill-opacity': 0.5,
        stroke: '#FFF',
      });
      // Displayed in the center
      return this.element.scrollTop(y - this.graphHeight / 2);
    }
  }
}
