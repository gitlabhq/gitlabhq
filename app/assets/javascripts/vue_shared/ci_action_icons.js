import cancelSVG from 'icons/_icon_action_cancel.svg';
import retrySVG from 'icons/_icon_action_retry.svg';
import playSVG from 'icons/_icon_action_play.svg';

export default function getActionIcon(action) {
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
    default:
      icon = '';
  }

  return icon;
}
