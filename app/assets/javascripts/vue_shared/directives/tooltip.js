import $ from 'jquery';

export default {
  bind(el) {
    $(el).tooltip();
  },

  componentUpdated(el) {
    $(el).tooltip('_fixTitle');
  },

  unbind(el) {
    $(el).tooltip('destroy');
  },
};
