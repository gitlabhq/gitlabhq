/* eslint-disable func-names, consistent-return, no-param-reassign */

import $ from 'jquery';
import { setCookie } from '~/lib/utils/common_utils';
import { hide, fixTitle } from '~/tooltips';
import { __ } from './locale';

const updateSidebarClasses = (layoutPage, rightSidebar, windowSize = window.innerWidth) => {
  let scrollBarWidth = 0;

  if (window.innerWidth && document?.documentElement?.clientWidth) {
    scrollBarWidth = window.innerWidth - document.documentElement.clientWidth;
  }
  if (windowSize + scrollBarWidth >= 992) {
    layoutPage.classList.remove('right-sidebar-expanded', 'right-sidebar-collapsed');
    rightSidebar.classList.remove('right-sidebar-collapsed');
    rightSidebar.classList.add('right-sidebar-expanded');
  } else {
    layoutPage.classList.add('right-sidebar-collapsed', 'is-merge-request');
    rightSidebar.classList.add('right-sidebar-collapsed');
    rightSidebar.classList.remove('right-sidebar-expanded');
  }
};

function Sidebar() {
  this.sidebar = $('aside');

  this.isMR = /projects:merge_requests:/.test(document.body.dataset.page);

  this.removeListeners();
  this.addEventListeners();
}

Sidebar.initialize = function () {
  if (!this.instance) {
    this.instance = new Sidebar();
  }
};

Sidebar.prototype.removeListeners = function () {
  this.sidebar.off('click', '.sidebar-collapsed-icon');
  // eslint-disable-next-line @gitlab/no-global-event-off
  this.sidebar.off('hidden.gl.dropdown');
  // eslint-disable-next-line @gitlab/no-global-event-off
  this.sidebar.off('hiddenGlDropdown');
  // eslint-disable-next-line @gitlab/no-global-event-off
  $('.dropdown').off('loading.gl.dropdown');
  // eslint-disable-next-line @gitlab/no-global-event-off
  $('.dropdown').off('loaded.gl.dropdown');
  $(document).off('click', '.js-sidebar-toggle');
};

Sidebar.prototype.addEventListeners = function () {
  const $document = $(document);

  this.sidebar.on('click', '.sidebar-collapsed-icon', this, this.sidebarCollapseClicked);
  this.sidebar.on('hidden.gl.dropdown', this, this.onSidebarDropdownHidden);
  this.sidebar.on('hiddenGlDropdown', this, this.onSidebarDropdownHidden);

  $document.on('click', '.js-sidebar-toggle', this.sidebarToggleClicked);

  const layoutPage = document.querySelector('.layout-page');
  const rightSidebar = document.querySelector('.js-right-sidebar');

  if (rightSidebar.classList.contains('right-sidebar-merge-requests')) {
    updateSidebarClasses(layoutPage, rightSidebar);

    const resizeHandler = new ResizeObserver((entries) => {
      for (const entry of entries) {
        updateSidebarClasses(layoutPage, rightSidebar, entry.contentRect.width);
      }
    });
    resizeHandler.observe(document.querySelector('html'));
  }
};

Sidebar.prototype.sidebarToggleClicked = function (e, triggered) {
  const $toggleButtons = $('.js-sidebar-toggle');
  const $collapseIcon = $('.js-sidebar-collapse');
  const $expandIcon = $('.js-sidebar-expand');
  const $toggleContainer = $('.js-sidebar-toggle-container');
  const isExpanded = $toggleContainer.data('is-expanded');
  const tooltipLabel = isExpanded ? __('Expand sidebar') : __('Collapse sidebar');
  e.preventDefault();

  if (isExpanded) {
    $toggleContainer.data('is-expanded', false);
    $collapseIcon.addClass('hidden');
    $expandIcon.removeClass('hidden');
    $('aside.right-sidebar')
      .removeClass('right-sidebar-expanded')
      .addClass('right-sidebar-collapsed');

    if (!this.isMR) {
      $('.layout-page').removeClass('right-sidebar-expanded').addClass('right-sidebar-collapsed');
    }
  } else {
    $toggleContainer.data('is-expanded', true);
    $expandIcon.addClass('hidden');
    $collapseIcon.removeClass('hidden');
    $('aside.right-sidebar')
      .removeClass('right-sidebar-collapsed')
      .addClass('right-sidebar-expanded');

    if (!this.isMR) {
      $('.layout-page').removeClass('right-sidebar-collapsed').addClass('right-sidebar-expanded');
    }
  }

  $toggleButtons.attr('data-original-title', tooltipLabel);
  $toggleButtons.attr('title', tooltipLabel);
  fixTitle($toggleButtons);
  hide($toggleButtons);

  if (!triggered) {
    setCookie('collapsed_gutter', $('.right-sidebar').hasClass('right-sidebar-collapsed'));
  }
};

Sidebar.prototype.sidebarCollapseClicked = function (e) {
  if ($(e.currentTarget).hasClass('js-dont-change-state')) {
    return;
  }
  const sidebar = e.data;
  e.preventDefault();
  const $block = $(this).closest('.block');
  return sidebar.openDropdown($block);
};

Sidebar.prototype.openDropdown = function (blockOrName) {
  const $block = typeof blockOrName === 'string' ? this.getBlock(blockOrName) : blockOrName;
  if (!this.isOpen()) {
    this.setCollapseAfterUpdate($block);
    this.toggleSidebar('open');
  }
};

Sidebar.prototype.setCollapseAfterUpdate = function ($block) {
  $block.addClass('collapse-after-update');
  return $('.layout-page').addClass('with-overlay');
};

Sidebar.prototype.onSidebarDropdownHidden = function (e) {
  const sidebar = e.data;
  e.preventDefault();
  const $block = $(e.target).closest('.block');
  return sidebar.sidebarDropdownHidden($block);
};

Sidebar.prototype.sidebarDropdownHidden = function ($block) {
  if ($block.hasClass('collapse-after-update')) {
    $block.removeClass('collapse-after-update');
    $('.layout-page').removeClass('with-overlay');
    return this.toggleSidebar('hide');
  }
};

Sidebar.prototype.triggerOpenSidebar = function () {
  return this.sidebar.find('.js-sidebar-toggle').trigger('click');
};

Sidebar.prototype.toggleSidebar = function (action) {
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

Sidebar.prototype.isOpen = function () {
  return this.sidebar.is('.right-sidebar-expanded');
};

Sidebar.prototype.getBlock = function (name) {
  return this.sidebar.find(`.block.${name}`);
};

export default Sidebar;
