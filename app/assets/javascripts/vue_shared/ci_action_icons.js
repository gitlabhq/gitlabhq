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
<<<<<<< HEAD
  let icon;
  switch (action) {
    case 'icon_action_cancel':
      icon = cancelSVG;
      break;
    case 'icon_action_retry':
      icon = retrySVG;
      break;
    case 'icon_action_play':
      icon = playSVG;
      break;
    case 'icon_action_stop':
      icon = stopSVG;
      break;
    default:
      icon = '';
  }
=======
  const icons = {
    icon_action_cancel: cancelSVG,
    icon_action_play: playSVG,
    icon_action_retry: retrySVG,
    icon_action_stop: stopSVG,
  };
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259

  return icons[action] || '';
}
