import Hook from './hook';

class HookButton extends Hook {
  // eslint-disable-next-line max-params
  constructor(trigger, list, plugins, config) {
    super(trigger, list, plugins, config);

    this.type = 'button';
    this.event = 'click';

    this.eventWrapper = {};

    this.addEvents();
    this.addPlugins();
  }

  addPlugins() {
    this.plugins.forEach((plugin) => plugin.init(this));
  }

  clicked(e) {
    e.preventDefault();

    const buttonEvent = new CustomEvent('click.dl', {
      detail: {
        hook: this,
      },
      bubbles: true,
      cancelable: true,
    });
    e.target.dispatchEvent(buttonEvent);

    this.list.toggle();
  }

  addEvents() {
    this.eventWrapper.clicked = this.clicked.bind(this);
    this.trigger.addEventListener('click', this.eventWrapper.clicked);
  }

  removeEvents() {
    this.trigger.removeEventListener('click', this.eventWrapper.clicked);
  }

  restoreInitialState() {
    // eslint-disable-next-line no-unsanitized/property
    this.list.list.innerHTML = this.list.initialState;
  }

  removePlugins() {
    this.plugins.forEach((plugin) => plugin.destroy());
  }

  destroy() {
    this.restoreInitialState();

    this.removeEvents();
    this.removePlugins();
  }
}

export default HookButton;
