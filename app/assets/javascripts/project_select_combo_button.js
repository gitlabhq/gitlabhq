import $ from 'jquery';
import AccessorUtilities from './lib/utils/accessor';

export default class ProjectSelectComboButton {
  constructor(select) {
    this.projectSelectInput = $(select);
    this.newItemBtn = $('.new-project-item-link');
    this.resourceType = this.newItemBtn.data('type');
    this.resourceLabel = this.newItemBtn.data('label');
    this.formattedText = this.deriveTextVariants();
    this.groupId = this.projectSelectInput.data('groupId');
    this.bindEvents();
    this.initLocalStorage();
  }

  bindEvents() {
    this.projectSelectInput.siblings('.new-project-item-select-button')
      .on('click', e => this.openDropdown(e));

    this.newItemBtn.on('click', (e) => {
      if (!this.getProjectFromLocalStorage()) {
        e.preventDefault();
        this.openDropdown(e);
      }
    });

    this.projectSelectInput.on('change', () => this.selectProject());
  }

  initLocalStorage() {
    const localStorageIsSafe = AccessorUtilities.isLocalStorageAccessSafe();

    if (localStorageIsSafe) {
      this.localStorageKey = ['group', this.groupId, this.formattedText.localStorageItemType, 'recent-project'].join('-');
      this.setBtnTextFromLocalStorage();
    }
  }

  // eslint-disable-next-line class-methods-use-this
  openDropdown(event) {
    $(event.currentTarget).siblings('.project-item-select').select2('open');
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
      this.newItemBtn.text(`${this.formattedText.defaultTextPrefix} in ${project.name}`);
    } else {
      this.newItemBtn.text(`Select project to create ${this.formattedText.presetTextSuffix}`);
    }
  }

  getProjectFromLocalStorage() {
    const projectString = localStorage.getItem(this.localStorageKey);

    return JSON.parse(projectString);
  }

  setProjectInLocalStorage(projectMeta) {
    const projectString = JSON.stringify(projectMeta);

    localStorage.setItem(this.localStorageKey, projectString);
  }

  deriveTextVariants() {
    const defaultTextPrefix = this.resourceLabel;

    // the trailing slice call depluralizes each of these strings (e.g. new-issues -> new-issue)
    const localStorageItemType = `new-${this.resourceType.split('_').join('-').slice(0, -1)}`;
    const presetTextSuffix = this.resourceType.split('_').join(' ').slice(0, -1);

    return {
      localStorageItemType, // new-issue / new-merge-request
      defaultTextPrefix, // New issue / New merge request
      presetTextSuffix, // issue / merge request
    };
  }
}

