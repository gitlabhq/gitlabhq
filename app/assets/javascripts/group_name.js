
import _ from 'underscore';

export default class GroupName {
  constructor() {
    this.titleContainer = document.querySelector('.title-container');
    this.title = document.querySelector('.title');
    this.titleWidth = this.title.offsetWidth;
    this.groupTitle = document.querySelector('.group-title');
    this.groups = document.querySelectorAll('.group-path');
    this.toggle = null;
    this.isHidden = false;
    this.init();
  }

  init() {
    if (this.groups.length > 0) {
      this.groups[this.groups.length - 1].classList.remove('hidable');
      this.toggleHandler();
      window.addEventListener('resize', _.debounce(this.toggleHandler.bind(this), 100));
    }
    this.render();
  }

  toggleHandler() {
    if (this.titleWidth > this.titleContainer.offsetWidth) {
      if (!this.toggle) this.createToggle();
      this.showToggle();
    } else if (this.toggle) {
      this.hideToggle();
    }
  }

  createToggle() {
    this.toggle = document.createElement('button');
    this.toggle.className = 'text-expander group-name-toggle';
    this.toggle.setAttribute('aria-label', 'Toggle full path');
    this.toggle.innerHTML = '...';
    this.toggle.addEventListener('click', this.toggleGroups.bind(this));
    this.titleContainer.insertBefore(this.toggle, this.title);
    this.toggleGroups();
  }

  showToggle() {
    this.title.classList.add('wrap');
    this.toggle.classList.remove('hidden');
    if (this.isHidden) this.groupTitle.classList.add('is-hidden');
  }

  hideToggle() {
    this.title.classList.remove('wrap');
    this.toggle.classList.add('hidden');
    if (this.isHidden) this.groupTitle.classList.remove('is-hidden');
  }

  toggleGroups() {
    this.isHidden = !this.isHidden;
    this.groupTitle.classList.toggle('is-hidden');
  }

  render() {
    this.title.classList.remove('initializing');
  }
}
