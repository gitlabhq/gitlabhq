class StickyTabs {
  constructor(stickyTabs, unstickyTabs) {
    this.stickyTabs = stickyTabs;
    this.unstickyTabs = unstickyTabs;

    this.unstickyTabsHeight = this.unstickyTabs.offsetHeight;

    this.eventListeners = {};
  }

  bindEvents() {
    this.eventListeners.handleStickyTabs = this.handleStickyTabs.bind(this);

    document.addEventListener('scroll', this.eventListeners.handleStickyTabs);
  }

  unbindEvents() {
    document.removeEventListener('scroll', this.eventListeners.handleStickyTabs);
  }

  handleStickyTabs() {
    if (this.unstickyTabs.getBoundingClientRect().top <= this.unstickyTabsHeight) {
      this.unstickyTabs.classList.add('invisible');
      this.stickyTabs.classList.remove('hide');
    } else {
      this.unstickyTabs.classList.remove('invisible');
      this.stickyTabs.classList.add('hide');
    }
  }
}

export default StickyTabs;
