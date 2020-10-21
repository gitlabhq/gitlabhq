import $ from 'jquery';
import '~/commons/bootstrap';
import { parseBoolean } from '~/lib/utils/common_utils';

export default {
  bind(el) {
    const glTooltipDelay = localStorage.getItem('gl-tooltip-delay');
    const delay = glTooltipDelay ? JSON.parse(glTooltipDelay) : 0;

    $(el).tooltip({
      trigger: 'hover',
      delay,
      // By default, sanitize is run even if there is no `html` or `template` present
      // so let's optimize to only run this when necessary.
      // https://github.com/twbs/bootstrap/blob/c5966de27395a407f9a3d20d0eb2ff8e8fb7b564/js/src/tooltip.js#L716
      sanitize: parseBoolean(el.dataset.html) || Boolean(el.dataset.template),
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
