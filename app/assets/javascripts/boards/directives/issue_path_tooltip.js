import $ from 'jquery';

const toggleTooltip = (el) => {
  // If the element has an ellipsis enable tooltips else disable
  $(el).tooltip((el.offsetWidth < el.scrollWidth) ? 'enable' : 'disable');
};

export default {
  inserted(el) {
    toggleTooltip(el);
  },

  componentUpdated(el) {
    toggleTooltip(el);
  },
};
