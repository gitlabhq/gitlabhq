/* eslint-disable func-names, consistent-return, no-else-return, no-param-reassign */

import $ from 'jquery';
import _ from 'underscore';
import Cookies from 'js-cookie';
import flash from './flash';
import axios from './lib/utils/axios_utils';
import { sprintf, s__, __ } from './locale';

function Sidebar() {
  this.toggleTodo = this.toggleTodo.bind(this);
  this.sidebar = $('aside');

  this.removeListeners();
  this.addEventListeners();
}

Sidebar.initialize = function() {
  if (!this.instance) {
    this.instance = new Sidebar();
  }
};

Sidebar.prototype.removeListeners = function() {
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
  return $(document)
    .off('click', '.js-issuable-todo')
    .on('click', '.js-issuable-todo', this.toggleTodo);
};

Sidebar.prototype.sidebarToggleClicked = function(e, triggered) {
  const $this = $(this);
  const isExpanded = $this.find('i').hasClass('fa-angle-double-right');
  const tooltipLabel = isExpanded ? __('Expand sidebar') : __('Collapse sidebar');
  const $allGutterToggleIcons = $('.js-sidebar-toggle i');
  e.preventDefault();

  if (isExpanded) {
    $allGutterToggleIcons.removeClass('fa-angle-double-right').addClass('fa-angle-double-left');
    $('aside.right-sidebar')
      .removeClass('right-sidebar-expanded')
      .addClass('right-sidebar-collapsed');
    $('.layout-page')
      .removeClass('right-sidebar-expanded')
      .addClass('right-sidebar-collapsed');
  } else {
    $allGutterToggleIcons.removeClass('fa-angle-double-left').addClass('fa-angle-double-right');
    $('aside.right-sidebar')
      .removeClass('right-sidebar-collapsed')
      .addClass('right-sidebar-expanded');
    $('.layout-page')
      .removeClass('right-sidebar-collapsed')
      .addClass('right-sidebar-expanded');
  }

  $this.attr('data-original-title', tooltipLabel);

  if (!triggered) {
    Cookies.set('collapsed_gutter', $('.right-sidebar').hasClass('right-sidebar-collapsed'));
  }
};

Sidebar.prototype.toggleTodo = function(e) {
  const $this = $(e.currentTarget);
  const ajaxType = $this.data('deletePath') ? 'delete' : 'post';
  const url = String($this.data('deletePath') || $this.data('createPath'));

  $this.tooltip('hide');

  $('.js-issuable-todo')
    .disable()
    .addClass('is-loading');

  axios[ajaxType](url, {
    issuable_id: $this.data('issuableId'),
    issuable_type: $this.data('issuableType'),
  })
    .then(({ data }) => {
      this.todoUpdateDone(data);
    })
    .catch(() =>
      flash(
        sprintf(__('There was an error %{message} todo.'), {
          message:
            ajaxType === 'post' ? s__('RightSidebar|adding a') : s__('RightSidebar|deleting the'),
        }),
      ),
    );
};

Sidebar.prototype.todoUpdateDone = function(data) {
  const deletePath = data.delete_path ? data.delete_path : null;
  const attrPrefix = deletePath ? 'mark' : 'todo';
  const $todoBtns = $('.js-issuable-todo');

  $(document).trigger('todo:toggle', data.count);

  $todoBtns.each((i, el) => {
    const $el = $(el);
    const $elText = $el.find('.js-issuable-todo-inner');

    $el
      .removeClass('is-loading')
      .enable()
      .attr('aria-label', $el.data(`${attrPrefix}Text`))
      .attr('title', $el.data(`${attrPrefix}Text`))
      .data('deletePath', deletePath);

    if ($el.hasClass('has-tooltip')) {
      $el.tooltip('_fixTitle');
    }

    if (typeof $el.data('isCollapsed') !== 'undefined') {
      $elText.html($el.data(`${attrPrefix}Icon`));
    } else {
      $elText.text($el.data(`${attrPrefix}Text`));
    }
  });
};

Sidebar.prototype.sidebarDropdownLoading = function() {
  const $sidebarCollapsedIcon = $(this)
    .closest('.block')
    .find('.sidebar-collapsed-icon');
  const img = $sidebarCollapsedIcon.find('img');
  const i = $sidebarCollapsedIcon.find('i');
  const $loading = $('<i class="fa fa-spinner fa-spin"></i>');
  if (img.length) {
    img.before($loading);
    return img.hide();
  } else if (i.length) {
    i.before($loading);
    return i.hide();
  }
};

Sidebar.prototype.sidebarDropdownLoaded = function() {
  const $sidebarCollapsedIcon = $(this)
    .closest('.block')
    .find('.sidebar-collapsed-icon');
  const img = $sidebarCollapsedIcon.find('img');
  $sidebarCollapsedIcon.find('i.fa-spin').remove();
  const i = $sidebarCollapsedIcon.find('i');
  if (img.length) {
    return img.show();
  } else {
    return i.show();
  }
};

Sidebar.prototype.sidebarCollapseClicked = function(e) {
  if ($(e.currentTarget).hasClass('dont-change-state')) {
    return;
  }
  const sidebar = e.data;
  e.preventDefault();
  const $block = $(this).closest('.block');
  return sidebar.openDropdown($block);
};

Sidebar.prototype.openDropdown = function(blockOrName) {
  const $block = _.isString(blockOrName) ? this.getBlock(blockOrName) : blockOrName;
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
  const sidebar = e.data;
  e.preventDefault();
  const $block = $(e.target).closest('.block');
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
  return this.sidebar.find(`.block.${name}`);
};

export default Sidebar;
