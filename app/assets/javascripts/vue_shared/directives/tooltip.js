import $ from 'jquery';
import '~/commons/bootstrap';

export default {
  bind(el) {
    const glTooltipDelay = localStorage.getItem('gl-tooltip-delay');
    const delay = glTooltipDelay ? JSON.parse(glTooltipDelay) : 0;

    $(el).tooltip({
      trigger: 'hover',
      delay,
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
