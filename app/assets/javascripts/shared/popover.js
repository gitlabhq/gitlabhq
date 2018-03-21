export default class Popover {
  constructor(trigger, content) {
    this.isOpen = false;

    this.$popover = $(trigger).popover({
      content,
      html: true,
      placement: 'bottom',
      trigger: 'manual',
    });
  }

  init() {
    this.registerClickOpenListener();
  }

  openPopover() {
    if (this.isOpen) return;

    this.$popover.popover('show');
    this.$popover.one('shown.bs.popover', this.enableClose.bind(this));
    this.isOpen = true;
  }

  closePopover() {
    if (!this.isOpen) return;

    this.$popover.popover('hide');
    this.disableClose();
    this.isOpen = false;
  }

  closePopoverClick(event) {
    const $target = $(event.target);

    if ($target.is(this.$popover) ||
      $target.is('.popover') ||
      $target.parents('.popover').length > 0) return;

    this.closePopover();
  }

  closePopoverMouseleave() {
    setTimeout(() => {
      if (this.$popover.is(':hover') ||
        (this.$popover.siblings('.popover').length > 0 &&
        this.$popover.siblings('.popover').is(':hover'))) return;

      this.closePopover();
    }, 1500);
  }

  registerClickOpenListener() {
    this.$popover.on('click.glPopover.open', this.openPopover.bind(this));
  }

  registerClickCloseListener() {
    $(document.body).on('click.glPopover.close', this.closePopoverClick.bind(this));
  }

  registerMouseleaveCloseListener() {
    this.$popover.on('mouseleave.glPopover.close', this.closePopoverMouseleave.bind(this));
    this.$popover.siblings('.popover').on('mouseleave.glPopover.close', this.closePopoverMouseleave.bind(this));
  }

  destroyMouseleaveCloseListener() {
    this.$popover.off('mouseleave.glPopover.close');
    this.$popover.siblings('.popover').on('mouseleave.glPopover.close');
  }

  enableClose() {
    this.registerClickCloseListener();
    this.registerMouseleaveCloseListener();
  }

  disableClose() {
    Popover.destroyClickCloseListener();
    this.destroyMouseleaveCloseListener();
  }

  static destroyClickCloseListener() {
    $(document.body).off('click.glPopover.close');
  }
}
