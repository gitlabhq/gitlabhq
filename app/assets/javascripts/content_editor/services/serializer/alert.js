import { ALERT_TYPES } from '../../constants/alert_types';
import blockquote from './blockquote';

let alertType = ALERT_TYPES.NOTE;

export const setAlertType = (type) => {
  alertType = type;
};

export const getAlertType = () => alertType;
export const unsetAlertType = () => {
  alertType = ALERT_TYPES.NOTE;
};

function alert(state, node) {
  setAlertType(node.attrs.type || ALERT_TYPES.NOTE);
  blockquote(state, node);
  unsetAlertType();
}

export default alert;
