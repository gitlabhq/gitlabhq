import Cookies from 'js-cookie';
import _ from 'underscore';

export default class GroupName {
  constructor() {
    this.titleContainer = document.querySelector('.js-title-container');
    this.title = this.titleContainer.querySelector('.title');

    if (this.title) {
      this.titleWidth = this.title.offsetWidth;
      this.groupTitle = this.titleContainer.querySelector('.group-title');
      this.groups = this.titleContainer.querySelectorAll('.group-path');
      this.toggle = null;
      this.isHidden = false;
      this.init();
    }
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
    this.toggle.setAttribute('type', 'button');
    this.toggle.className = 'text-expander group-name-toggle';
    this.toggle.setAttribute('aria-label', 'Toggle full path');
    if (Cookies.get('new_nav') === 'true') {
      this.toggle.innerHTML = '<i class="fa fa-ellipsis-h" aria-hidden="true"></i>';
    } else {
      this.toggle.innerHTML = '...';
    }
    this.toggle.addEventListener('click', this.toggleGroups.bind(this));
    if (Cookies.get('new_nav') === 'true') {
      this.title.insertBefore(this.toggle, this.groupTitle);
    } else {
      this.titleContainer.insertBefore(this.toggle, this.title);
    }
    this.toggleGroups();
  }

  showToggle() {
    this.title.classList.add('wrap');
    this.toggle.classList.remove('hidden');
    if (this.isHidden) this.groupTitle.classList.add('hidden');
  }

  hideToggle() {
    this.title.classList.remove('wrap');
    this.toggle.classList.add('hidden');
    if (this.isHidden) this.groupTitle.classList.remove('hidden');
  }

  toggleGroups() {
    this.isHidden = !this.isHidden;
    this.groupTitle.classList.toggle('hidden');
  }

  render() {
    this.title.classList.remove('initializing');
  }
}
