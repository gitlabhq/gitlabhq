import $ from 'jquery';

export default {
  componentUpdated(el) {
    $(el).dropdown('toggle');
  },

  unbind(el) {
    $(el).dropdown('dispose');
  },
};
