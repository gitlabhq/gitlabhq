import DropLab from './droplab/drop_lab';
import ISetter from './droplab/plugins/input_setter';

// Todo: Remove this when fixing issue in input_setter plugin
const InputSetter = Object.assign({}, ISetter);

class CloseReopenReportToggle {
  constructor(opts = {}) {
    this.dropdownTrigger = opts.dropdownTrigger;
    this.dropdownList = opts.dropdownList;
    this.button = opts.button;

    this.reopenItem = this.dropdownList.querySelector('.reopen-item');
    this.closeItem = this.dropdownList.querySelector('.close-item');
  }

  initDroplab() {
    this.droplab = new DropLab();

    const config = this.setConfig();

    this.droplab.init(this.dropdownTrigger, this.dropdownList, [InputSetter], config);
  }

  updateButton(isClosed) {
    const action = isClosed ? this.showReopen : this.showClose;

    action.call(this);
    this.button.blur();
  }

  showClose() {
    this.closeItem.classList.remove('hidden');
    this.closeItem.classList.add('droplab-item-selected');

    this.reopenItem.classList.add('hidden');
    this.reopenItem.classList.remove('droplab-item-selected');

    this.closeItem.click();
  }

  showReopen() {
    this.reopenItem.classList.remove('hidden');
    this.reopenItem.classList.add('droplab-item-selected');

    this.closeItem.classList.add('hidden');
    this.closeItem.classList.remove('droplab-item-selected');

    this.reopenItem.click();
  }

  setDisable(shouldDisable) {
    if (shouldDisable) {
      this.button.setAttribute('disabled', 'true');
      this.dropdownTrigger.setAttribute('disabled', 'true');
    } else {
      this.button.removeAttribute('disabled');
      this.dropdownTrigger.removeAttribute('disabled');
    }
  }

  setConfig() {
    const config = {
      InputSetter: [
        {
          input: this.button,
          valueAttribute: 'data-text',
          inputAttribute: 'data-value',
        },
        {
          input: this.button,
          valueAttribute: 'data-text',
          inputAttribute: 'title',
        },
        {
          input: this.button,
          valueAttribute: 'data-button-class',
          inputAttribute: 'class',
        },
        {
          input: this.dropdownTrigger,
          valueAttribute: 'data-toggle-class',
          inputAttribute: 'class',
        },
        {
          input: this.button,
          valueAttribute: 'data-url',
          inputAttribute: 'href',
        },
        {
          input: this.button,
          valueAttribute: 'data-method',
          inputAttribute: 'data-method',
        },
      ],
    };

    return config;
  }
}

export default CloseReopenReportToggle;
