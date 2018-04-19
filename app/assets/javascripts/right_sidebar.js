/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-unused-vars, consistent-return, one-var, one-var-declaration-per-line, quotes, prefer-template, object-shorthand, comma-dangle, no-else-return, no-param-reassign, max-len */

import $ from 'jquery';
import _ from 'underscore';
import Cookies from 'js-cookie';
import flash from './flash';
import axios from './lib/utils/axios_utils';
import { __ } from './locale';

function Sidebar(currentUser) {
  this.toggleTodo = this.toggleTodo.bind(this);
  this.sidebar = $('aside');

  this.removeListeners();
  this.addEventListeners();
}

Sidebar.initialize = function(currentUser) {
  if (!this.instance) {
    this.instance = new Sidebar(currentUser);
  }
};

Sidebar.prototype.removeListeners = function () {
  this.sidebar.off('click', '.sidebar-collapsed-icon');
  this.sidebar.off('hidden.gl.dropdown');
  $('.dropdown').off('loading.gl.dropdown');
  $('.dropdown').off('loaded.gl.dropdown');
  $(document).off('click', '.js-sidebar-toggle');
};

Sidebar.prototype.addEventListeners = function() {
  const $document = $(document);

  this.sidebar.on('click', '.sidebar-collapsed-icon', this, this.sidebarCollapseClicked);
  this.sidebar.on('hidden.gl.dropdown', this, this.onSidebarDropdownHidden);
  $('.dropdown').on('loading.gl.dropdown', this.sidebarDropdownLoading);
  $('.dropdown').on('loaded.gl.dropdown', this.sidebarDropdownLoaded);

  $document.on('click', '.js-sidebar-toggle', this.sidebarToggleClicked);
  return $(document).off('click', '.js-issuable-todo').on('click', '.js-issuable-todo', this.toggleTodo);
};

Sidebar.prototype.sidebarToggleClicked = function (e, triggered) {
  var $allGutterToggleIcons, $this, isExpanded, tooltipLabel;
  e.preventDefault();
  $this = $(this);
  isExpanded = $this.find('i').hasClass('fa-angle-double-right');
  tooltipLabel = isExpanded ? __('Expand sidebar') : __('Collapse sidebar');
  $allGutterToggleIcons = $('.js-sidebar-toggle i');

  if (isExpanded) {
    $allGutterToggleIcons.removeClass('fa-angle-double-right').addClass('fa-angle-double-left');
    $('aside.right-sidebar').removeClass('right-sidebar-expanded').addClass('right-sidebar-collapsed');
    $('.layout-page').removeClass('right-sidebar-expanded').addClass('right-sidebar-collapsed');
  } else {
    $allGutterToggleIcons.removeClass('fa-angle-double-left').addClass('fa-angle-double-right');
    $('aside.right-sidebar').removeClass('right-sidebar-collapsed').addClass('right-sidebar-expanded');
    $('.layout-page').removeClass('right-sidebar-collapsed').addClass('right-sidebar-expanded');

    if (gl.lazyLoader) gl.lazyLoader.loadCheck();
  }

  $this.attr('data-original-title', tooltipLabel);

  if (!triggered) {
    Cookies.set("collapsed_gutter", $('.right-sidebar').hasClass('right-sidebar-collapsed'));
  }
};

Sidebar.prototype.toggleTodo = function(e) {
  var $btnText, $this, $todoLoading, ajaxType, url;
  $this = $(e.currentTarget);
  ajaxType = $this.attr('data-delete-path') ? 'delete' : 'post';
  if ($this.attr('data-delete-path')) {
    url = "" + ($this.attr('data-delete-path'));
  } else {
    url = "" + ($this.data('url'));
  }

  $this.tooltip('hide');

  $('.js-issuable-todo').disable().addClass('is-loading');

  axios[ajaxType](url, {
    issuable_id: $this.data('issuableId'),
    issuable_type: $this.data('issuableType'),
  }).then(({ data }) => {
    this.todoUpdateDone(data);
  }).catch(() => flash(`There was an error ${ajaxType === 'post' ? 'adding a' : 'deleting the'} todo.`));
};

Sidebar.prototype.todoUpdateDone = function(data) {
  const deletePath = data.delete_path ? data.delete_path : null;
  const attrPrefix = deletePath ? 'mark' : 'todo';
  const $todoBtns = $('.js-issuable-todo');

  $(document).trigger('todo:toggle', data.count);

  $todoBtns.each((i, el) => {
    const $el = $(el);
    const $elText = $el.find('.js-issuable-todo-inner');

    $el.removeClass('is-loading')
      .enable()
      .attr('aria-label', $el.data(`${attrPrefix}Text`))
      .attr('data-delete-path', deletePath)
      .attr('title', $el.data(`${attrPrefix}Text`));

    if ($el.hasClass('has-tooltip')) {
      $el.tooltip('fixTitle');
    }

    if ($el.data(`${attrPrefix}Icon`)) {
      $elText.html($el.data(`${attrPrefix}Icon`));
    } else {
      $elText.text($el.data(`${attrPrefix}Text`));
    }
  });
};

Sidebar.prototype.sidebarDropdownLoading = function(e) {
  var $loading, $sidebarCollapsedIcon, i, img;
  $sidebarCollapsedIcon = $(this).closest('.block').find('.sidebar-collapsed-icon');
  img = $sidebarCollapsedIcon.find('img');
  i = $sidebarCollapsedIcon.find('i');
  $loading = $('<i class="fa fa-spinner fa-spin"></i>');
  if (img.length) {
    img.before($loading);
    return img.hide();
  } else if (i.length) {
    i.before($loading);
    return i.hide();
  }
};

Sidebar.prototype.sidebarDropdownLoaded = function(e) {
  var $sidebarCollapsedIcon, i, img;
  $sidebarCollapsedIcon = $(this).closest('.block').find('.sidebar-collapsed-icon');
  img = $sidebarCollapsedIcon.find('img');
  $sidebarCollapsedIcon.find('i.fa-spin').remove();
  i = $sidebarCollapsedIcon.find('i');
  if (img.length) {
    return img.show();
  } else {
    return i.show();
  }
};

Sidebar.prototype.sidebarCollapseClicked = function(e) {
  var $block, sidebar;
  if ($(e.currentTarget).hasClass('dont-change-state')) {
    return;
  }
  sidebar = e.data;
  e.preventDefault();
  $block = $(this).closest('.block');
  return sidebar.openDropdown($block);
};

Sidebar.prototype.openDropdown = function(blockOrName) {
  var $block;
  $block = _.isString(blockOrName) ? this.getBlock(blockOrName) : blockOrName;
  if (!this.isOpen()) {
    this.setCollapseAfterUpdate($block);
    this.toggleSidebar('open');
  }

  // Wait for the sidebar to trigger('click') open
  // so it doesn't cause our dropdown to close preemptively
  setTimeout(() => {
    $block.find('.js-sidebar-dropdown-toggle').trigger('click');
  });
};

Sidebar.prototype.setCollapseAfterUpdate = function($block) {
  $block.addClass('collapse-after-update');
  return $('.layout-page').addClass('with-overlay');
};

Sidebar.prototype.onSidebarDropdownHidden = function(e) {
  var $block, sidebar;
  sidebar = e.data;
  e.preventDefault();
  $block = $(e.target).closest('.block');
  return sidebar.sidebarDropdownHidden($block);
};

Sidebar.prototype.sidebarDropdownHidden = function($block) {
  if ($block.hasClass('collapse-after-update')) {
    $block.removeClass('collapse-after-update');
    $('.layout-page').removeClass('with-overlay');
    return this.toggleSidebar('hide');
  }
};

Sidebar.prototype.triggerOpenSidebar = function() {
  return this.sidebar.find('.js-sidebar-toggle').trigger('click');
};

Sidebar.prototype.toggleSidebar = function(action) {
  if (action == null) {
    action = 'toggle';
  }
  if (action === 'toggle') {
    this.triggerOpenSidebar();
  }
  if (action === 'open') {
    if (!this.isOpen()) {
      this.triggerOpenSidebar();
    }
  }
  if (action === 'hide') {
    if (this.isOpen()) {
      return this.triggerOpenSidebar();
    }
  }
};

Sidebar.prototype.isOpen = function() {
  return this.sidebar.is('.right-sidebar-expanded');
};

Sidebar.prototype.getBlock = function(name) {
  return this.sidebar.find(".block." + name);
};

export default Sidebar;
