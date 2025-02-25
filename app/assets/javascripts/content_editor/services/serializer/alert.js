import { preserveUnchanged } from '../serialization_helpers';
import { ALERT_TYPES } from '../../constants/alert_types';
import { renderBlockquote } from './blockquote';

let alertType = ALERT_TYPES.NOTE;

export const setAlertType = (type) => {
  alertType = type;
};

export const getAlertType = () => alertType;
export const unsetAlertType = () => {
  alertType = ALERT_TYPES.NOTE;
};

const alert = preserveUnchanged((state, node) => {
  setAlertType(node.attrs.type || ALERT_TYPES.NOTE);
  renderBlockquote(state, node);
  unsetAlertType();
});

export default alert;
