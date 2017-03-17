const GROUP_LIMIT = 2;

export default class GroupName {
  constructor() {
    this.titleContainer = document.querySelector('.title');
    this.groups = document.querySelectorAll('.group-path');
    this.groupTitle = document.querySelector('.group-title');
    this.toggle = null;
    this.isHidden = false;
    this.init();
  }

  init() {
    if (this.groups.length > GROUP_LIMIT) {
      this.groups[this.groups.length - 1].classList.remove('hidable');
      this.addToggle();
    }
    this.render();
  }

  addToggle() {
    const header = document.querySelector('.header-content');
    this.toggle = document.createElement('button');
    this.toggle.className = 'text-expander group-name-toggle';
    this.toggle.setAttribute('aria-label', 'Toggle full path');
    this.toggle.innerHTML = '...';
    this.toggle.addEventListener('click', this.toggleGroups.bind(this));
    header.insertBefore(this.toggle, this.titleContainer);
    this.toggleGroups();
  }

  toggleGroups() {
    this.isHidden = !this.isHidden;
    this.groupTitle.classList.toggle('is-hidden');
  }

  render() {
    this.titleContainer.classList.remove('initializing');
  }
}
