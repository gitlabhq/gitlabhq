import $ from 'jquery';

export default {
  bind(el) {
    $(el).tooltip();
  },

  componentUpdated(el) {
    $(el).tooltip('fixTitle');
  },

  unbind(el) {
    $(el).tooltip('destroy');
  },
};
