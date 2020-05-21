import $ from 'jquery';

// bootstrap jQuery plugins
import 'bootstrap';

// custom jQuery functions
$.fn.extend({
  disable() {
    return $(this)
      .prop('disabled', true)
      .addClass('disabled');
  },
  enable() {
    return $(this)
      .prop('disabled', false)
      .removeClass('disabled');
  },
});

/*
 Starting with bootstrap 4.3.1, bootstrap sanitizes html used for tooltips / popovers.
 This extends the default whitelists with more elements / attributes:
 https://getbootstrap.com/docs/4.3/getting-started/javascript/#sanitizer
 */
const whitelist = $.fn.tooltip.Constructor.Default.whiteList;

const inputAttributes = ['value', 'type'];

const dataAttributes = [
  'data-toggle',
  'data-placement',
  'data-container',
  'data-title',
  'data-class',
  'data-clipboard-text',
  'data-placement',
];

// Whitelisting data attributes
whitelist['*'] = [
  ...whitelist['*'],
  ...dataAttributes,
  'title',
  'width height',
  'abbr',
  'datetime',
  'name',
  'width',
  'height',
];

// Whitelist missing elements:
whitelist.label = ['for'];
whitelist.button = [...inputAttributes];
whitelist.input = [...inputAttributes];

whitelist.tt = [];
whitelist.samp = [];
whitelist.kbd = [];
whitelist.var = [];
whitelist.dfn = [];
whitelist.cite = [];
whitelist.big = [];
whitelist.address = [];
whitelist.dl = [];
whitelist.dt = [];
whitelist.dd = [];
whitelist.abbr = [];
whitelist.acronym = [];
whitelist.blockquote = [];
whitelist.del = [];
whitelist.ins = [];
whitelist['gl-emoji'] = [
  'data-name',
  'data-unicode-version',
  'data-fallback-src',
  'data-fallback-sprite-class',
];

// Whitelisting SVG tags and attributes
whitelist.svg = ['viewBox'];
whitelist.use = ['xlink:href'];
whitelist.path = ['d'];
