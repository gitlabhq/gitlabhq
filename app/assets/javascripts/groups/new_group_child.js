import { visitUrl } from '../lib/utils/url_utility';
import DropLab from '../droplab/drop_lab';
import ISetter from '../droplab/plugins/input_setter';

const InputSetter = Object.assign({}, ISetter);

const NEW_PROJECT = 'new-project';
const NEW_SUBGROUP = 'new-subgroup';

export default class NewGroupChild {
  constructor(buttonWrapper) {
    this.buttonWrapper = buttonWrapper;
    this.newGroupChildButton = this.buttonWrapper.querySelector('.js-new-group-child');
    this.dropdownToggle = this.buttonWrapper.querySelector('.js-dropdown-toggle');
    this.dropdownList = this.buttonWrapper.querySelector('.dropdown-menu');

    this.newGroupPath = this.buttonWrapper.dataset.projectPath;
    this.subgroupPath = this.buttonWrapper.dataset.subgroupPath;

    this.init();
  }

  init() {
    this.initDroplab();
    this.bindEvents();
  }

  initDroplab() {
    this.droplab = new DropLab();
    this.droplab.init(
      this.dropdownToggle,
      this.dropdownList,
      [InputSetter],
      this.getDroplabConfig(),
    );
  }

  getDroplabConfig() {
    return {
      InputSetter: [{
        input: this.newGroupChildButton,
        valueAttribute: 'data-value',
        inputAttribute: 'data-action',
      }, {
        input: this.newGroupChildButton,
        valueAttribute: 'data-text',
      }],
    };
  }

  bindEvents() {
    this.newGroupChildButton
      .addEventListener('click', this.onClickNewGroupChildButton.bind(this));
  }

  onClickNewGroupChildButton(e) {
    if (e.target.dataset.action === NEW_PROJECT) {
      visitUrl(this.newGroupPath);
    } else if (e.target.dataset.action === NEW_SUBGROUP) {
      visitUrl(this.subgroupPath);
    }
  }
}
