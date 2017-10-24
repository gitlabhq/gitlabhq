import _ from 'underscore';
import Cookies from 'js-cookie';

export default class RightSidebar {
  constructor() {
    this.sidebar = $('aside');

    this.removeListeners();
    this.addEventListeners();
  }

  removeListeners() {
    this.sidebar.off('click', '.sidebar-collapsed-icon');
    $('.dropdown').off('hidden.gl.dropdown');
    $('.dropdown').off('loading.gl.dropdown');
    $('.dropdown').off('loaded.gl.dropdown');
    $(document).off('click', '.js-sidebar-toggle');
  }

  addEventListeners() {
    const $document = $(document);

    this.sidebar.on('click', '.sidebar-collapsed-icon', this, this.sidebarCollapseClicked);
    $('.dropdown').on('hidden.gl.dropdown', this, this.onSidebarDropdownHidden);
    $('.dropdown').on('loading.gl.dropdown', this.sidebarDropdownLoading);
    $('.dropdown').on('loaded.gl.dropdown', this.sidebarDropdownLoaded);

    $document.on('click', '.js-sidebar-toggle', this.sidebarToggleClicked);
    $(document).off('click', '.js-issuable-todo').on('click', '.js-issuable-todo', RightSidebar.toggleTodo);
  }

  sidebarToggleClicked(e, triggered) {
    e.preventDefault();

    const $allGutterToggleIcons = $('.js-sidebar-toggle i');
    const $this = $(this);
    const $thisIcon = $this.find('i');

    if ($thisIcon.hasClass('fa-angle-double-right')) {
      $allGutterToggleIcons.removeClass('fa-angle-double-right').addClass('fa-angle-double-left');
      $('aside.right-sidebar').removeClass('right-sidebar-expanded').addClass('right-sidebar-collapsed');
      $('.page-with-sidebar').removeClass('right-sidebar-expanded').addClass('right-sidebar-collapsed');
    } else {
      $allGutterToggleIcons.removeClass('fa-angle-double-left').addClass('fa-angle-double-right');
      $('aside.right-sidebar').removeClass('right-sidebar-collapsed').addClass('right-sidebar-expanded');
      $('.page-with-sidebar').removeClass('right-sidebar-collapsed').addClass('right-sidebar-expanded');

      if (gl.lazyLoader) gl.lazyLoader.loadCheck();
    }
    if (!triggered) {
      Cookies.set('collapsed_gutter', $('.right-sidebar').hasClass('right-sidebar-collapsed'));
    }
  }

  static toggleTodo(e) {
    const $currentTarget = $(e.currentTarget);
    const ajaxType = $currentTarget.attr('data-delete-path') ? 'DELETE' : 'POST';
    let url;

    if ($currentTarget.attr('data-delete-path')) {
      url = $currentTarget.attr('data-delete-path');
    } else {
      url = $currentTarget.data('url');
    }

    $currentTarget.tooltip('hide');

    $.ajax({
      url,
      type: ajaxType,
      dataType: 'json',
      data: {
        issuable_id: $currentTarget.data('issuable-id'),
        issuable_type: $currentTarget.data('issuable-type'),
      },
      beforeSend: () => {
        $('.js-issuable-todo').disable()
          .addClass('is-loading');
      },
    }).done(data => RightSidebar.todoUpdateDone(data));
  }

  static todoUpdateDone(data) {
    const deletePath = data.delete_path ? data.delete_path : null;
    const attrPrefix = deletePath ? 'mark' : 'todo';
    const $todoBtns = $('.js-issuable-todo');

    $(document).trigger('todo:toggle', data.count);

    $todoBtns.each((i, el) => {
      const $el = $(el);
      const $elText = $el.find('.js-issuable-todo-inner');

      $el.removeClass('is-loading')
        .enable()
        .attr('aria-label', $el.data(`${attrPrefix}-text`))
        .attr('data-delete-path', deletePath)
        .attr('title', $el.data(`${attrPrefix}-text`));

      if ($el.hasClass('has-tooltip')) {
        $el.tooltip('fixTitle');
      }

      if ($el.data(`${attrPrefix}-icon`)) {
        $elText.html($el.data(`${attrPrefix}-icon`));
      } else {
        $elText.text($el.data(`${attrPrefix}-text`));
      }
    });
  }

  sidebarDropdownLoading() {
    const $sidebarCollapsedIcon = $(this).closest('.block').find('.sidebar-collapsed-icon');
    const img = $sidebarCollapsedIcon.find('img');
    const i = $sidebarCollapsedIcon.find('i');
    const $loading = $('<i class="fa fa-spinner fa-spin"></i>');

    if (img.length) {
      img.before($loading);
      img.hide();
    } else if (i.length) {
      i.before($loading);
      i.hide();
    }
  }

  sidebarCollapseClicked(e) {
    if ($(e.currentTarget).hasClass('dont-change-state')) {
      return;
    }

    e.preventDefault();

    const sidebar = e.data;
    const $block = $(this).closest('.block');
    sidebar.openDropdown($block);
  }

  openDropdown(blockOrName) {
    const $block = _.isString(blockOrName) ? this.getBlock(blockOrName) : blockOrName;
    if (!this.isOpen()) {
      RightSidebar.setCollapseAfterUpdate($block);
      this.toggleSidebar('open');
    }

    // Wait for the sidebar to trigger('click') open
    // so it doesn't cause our dropdown to close preemptively
    setTimeout(() => {
      $block.find('.js-sidebar-dropdown-toggle').trigger('click');
    });
  }

  static setCollapseAfterUpdate($block) {
    $block.addClass('collapse-after-update');
    $('.page-with-sidebar').addClass('with-overlay');
  }

  onSidebarDropdownHidden(e) {
    e.preventDefault();
    const sidebar = e.data;
    const $block = $(this).closest('.block');
    sidebar.sidebarDropdownHidden($block);
  }

  sidebarDropdownHidden($block) {
    if ($block.hasClass('collapse-after-update')) {
      $block.removeClass('collapse-after-update');
      $('.page-with-sidebar').removeClass('with-overlay');
      this.toggleSidebar('hide');
    }
  }

  triggerOpenSidebar() {
    this.sidebar.find('.js-sidebar-toggle').trigger('click');
  }

  toggleSidebar(action = 'toggle') {
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
        this.triggerOpenSidebar();
      }
    }
  }

  isOpen() {
    return this.sidebar.is('.right-sidebar-expanded');
  }

  getBlock(name) {
    return this.sidebar.find(`.block.${name}`);
  }
}
