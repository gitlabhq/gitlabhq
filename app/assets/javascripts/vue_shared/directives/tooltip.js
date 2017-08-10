export default {
  bind(el) {
    $(el).tooltip();
  },

  componentUpdated(el) {
    $(el).tooltip('hide')
      .tooltip('fixTitle');
  },

  unbind(el) {
    $(el).tooltip('destroy');
  },
};
