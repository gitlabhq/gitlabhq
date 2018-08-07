import $ from 'jquery';

export default {
  bind(el) {
    requestAnimationFrame(() => {
      $(el).tooltip({
        trigger: 'hover',
      });
    });
  },

  componentUpdated(el) {
    $(el).tooltip('_fixTitle');
  },

  unbind(el) {
    $(el).tooltip('dispose');
  },
};
