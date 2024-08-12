import DropDown from './drop_down';

class Hook {
  // eslint-disable-next-line max-params
  constructor(trigger, list, plugins, config) {
    this.trigger = trigger;
    this.list = new DropDown(list, config);
    this.type = 'Hook';
    this.event = 'click';
    this.plugins = plugins || [];
    this.config = config || {};
    this.id = trigger.id;
  }
}

export default Hook;
