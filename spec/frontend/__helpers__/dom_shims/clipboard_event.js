window.ClipboardEvent = class ClipboardEvent extends Event {
  constructor(type, options) {
    super(type, { ...options, bubbles: true });
    this.clipboardData = options?.clipboardData || new DataTransfer();
  }
};
