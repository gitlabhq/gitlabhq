import $ from 'jquery';
import '~/commons/bootstrap';

export default {
  bind(el) {
    $(el).tooltip({
      trigger: 'hover',
    });
  },

  componentUpdated(el) {
    $(el).tooltip('_fixTitle');

    // update visible tooltips
    const tooltipInstance = $(el).data('bs.tooltip');
    const tip = tooltipInstance.getTipElement();
    tooltipInstance.setElementContent(
      $(tip.querySelectorAll('.tooltip-inner')),
      tooltipInstance.getTitle(),
    );
  },

  unbind(el) {
    $(el).tooltip('dispose');
  },
};
