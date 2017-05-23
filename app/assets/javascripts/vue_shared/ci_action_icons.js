import cancelSVG from 'icons/_icon_action_cancel.svg';
import retrySVG from 'icons/_icon_action_retry.svg';
import playSVG from 'icons/_icon_action_play.svg';
import stopSVG from 'icons/_icon_action_stop.svg';

/**
 * For the provided action returns the respective SVG
 *
 * @param  {String} action
 * @return {SVG|String}
 */
export default function getActionIcon(action) {
  const icons = {
    icon_action_cancel: cancelSVG,
    icon_action_play: playSVG,
    icon_action_retry: retrySVG,
    icon_action_stop: stopSVG,
  };

  return icons[action] || '';
}
