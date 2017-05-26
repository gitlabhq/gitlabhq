/* eslint-disable */

import utils from './utils';
import { SELECTED_CLASS, IGNORE_CLASS } from './constants';

var DropDown = function(list) {
  this.currentIndex = 0;
  this.hidden = true;
  this.list = typeof list === 'string' ? document.querySelector(list) : list;
  this.items = [];

  this.eventWrapper = {};

  this.getItems();
  this.initTemplateString();
  this.addEvents();

  this.initialState = list.innerHTML;
};

Object.assign(DropDown.prototype, {
  getItems: function() {
    this.items = [].slice.call(this.list.querySelectorAll('li'));
    return this.items;
  },

  initTemplateString: function() {
    var items = this.items || this.getItems();

    var templateString = '';
    if (items.length > 0) templateString = items[items.length - 1].outerHTML;
    this.templateString = templateString;

    return this.templateString;
  },

  clickEvent: function(e) {
    if (e.target.tagName === 'UL') return;
    if (e.target.classList.contains(IGNORE_CLASS)) return;

    var selected = utils.closest(e.target, 'LI');
    if (!selected) return;

    this.addSelectedClass(selected);

    e.preventDefault();
    this.hide();

    var listEvent = new CustomEvent('click.dl', {
      detail: {
        list: this,
        selected: selected,
        data: e.target.dataset,
      },
    });
    this.list.dispatchEvent(listEvent);
  },

  addSelectedClass: function (selected) {
    this.removeSelectedClasses();
    selected.classList.add(SELECTED_CLASS);
  },

  removeSelectedClasses: function () {
    const items = this.items || this.getItems();

    items.forEach(item => item.classList.remove(SELECTED_CLASS));
  },

  addEvents: function() {
    this.eventWrapper.clickEvent = this.clickEvent.bind(this)
    this.list.addEventListener('click', this.eventWrapper.clickEvent);
  },

  toggle: function() {
    this.hidden ? this.show() : this.hide();
  },

  setData: function(data) {
    this.data = data;
    this.render(data);
  },

  addData: function(data) {
    this.data = (this.data || []).concat(data);
    this.render(this.data);
  },

  render: function(data) {
    const children = data ? data.map(this.renderChildren.bind(this)) : [];
    const renderableList = this.list.querySelector('ul[data-dynamic]') || this.list;

    renderableList.innerHTML = children.join('');
  },

  renderChildren: function(data) {
    var html = utils.template(this.templateString, data);
    var template = document.createElement('div');

    template.innerHTML = html;
    this.setImagesSrc(template);
    template.firstChild.style.display = data.droplab_hidden ? 'none' : 'block';

    return template.firstChild.outerHTML;
  },

  setImagesSrc: function(template) {
    const images = [].slice.call(template.querySelectorAll('img[data-src]'));

    images.forEach((image) => {
      image.src = image.getAttribute('data-src');
      image.removeAttribute('data-src');
    });
  },

  show: function() {
    if (!this.hidden) return;
    this.list.style.display = 'block';
    this.currentIndex = 0;
    this.hidden = false;
  },

  hide: function() {
    if (this.hidden) return;
    this.list.style.display = 'none';
    this.currentIndex = 0;
    this.hidden = true;
  },

  toggle: function () {
    this.hidden ? this.show() : this.hide();
  },

  destroy: function() {
    this.hide();
    this.list.removeEventListener('click', this.eventWrapper.clickEvent);
  }
});

export default DropDown;
