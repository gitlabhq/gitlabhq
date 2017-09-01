import AccessorUtilities from './lib/utils/accessor';

export default class ProjectSelectComboButton {
  constructor(select) {
    this.projectSelectInput = $(select);
    this.newItemBtn = $('.new-project-item-link');
    this.newItemBtnBaseText = this.newItemBtn.data('label');
    this.itemType = this.deriveItemTypeFromLabel();
    this.groupId = this.projectSelectInput.data('groupId');

    this.bindEvents();
    this.initLocalStorage();
  }

  bindEvents() {
    this.projectSelectInput.siblings('.new-project-item-select-button')
      .on('click', this.openDropdown);

    this.projectSelectInput.on('change', () => this.selectProject());
  }

  initLocalStorage() {
    const localStorageIsSafe = AccessorUtilities.isLocalStorageAccessSafe();

    if (localStorageIsSafe) {
      const itemTypeKebabed = this.newItemBtnBaseText.toLowerCase().split(' ').join('-');

      this.localStorageKey = ['group', this.groupId, itemTypeKebabed, 'recent-project'].join('-');
      this.setBtnTextFromLocalStorage();
    }
  }

  openDropdown() {
    $(this).siblings('.project-item-select').select2('open');
  }

  selectProject() {
    const selectedProjectData = JSON.parse(this.projectSelectInput.val());
    const projectUrl = `${selectedProjectData.url}/${this.projectSelectInput.data('relativePath')}`;
    const projectName = selectedProjectData.name;

    const projectMeta = {
      url: projectUrl,
      name: projectName,
    };

    this.setNewItemBtnAttributes(projectMeta);
    this.setProjectInLocalStorage(projectMeta);
  }

  setBtnTextFromLocalStorage() {
    const cachedProjectData = this.getProjectFromLocalStorage();

    this.setNewItemBtnAttributes(cachedProjectData);
  }

  setNewItemBtnAttributes(project) {
    if (project) {
      this.newItemBtn.attr('href', project.url);
      this.newItemBtn.text(`New ${this.deriveItemTypeFromLabel()} in ${project.name}`);
      this.newItemBtn.enable();
    } else {
      this.newItemBtn.text(`Select project to create ${this.deriveItemTypeFromLabel()}`);
      this.newItemBtn.disable();
    }
  }

  deriveItemTypeFromLabel() {
    // label is either 'New issue' or 'New merge request'
    return this.newItemBtnBaseText.split(' ').slice(1).join(' ');
  }

  getProjectFromLocalStorage() {
    const projectString = localStorage.getItem(this.localStorageKey);

    return JSON.parse(projectString);
  }

  setProjectInLocalStorage(projectMeta) {
    const projectString = JSON.stringify(projectMeta);

    localStorage.setItem(this.localStorageKey, projectString);
  }
}

