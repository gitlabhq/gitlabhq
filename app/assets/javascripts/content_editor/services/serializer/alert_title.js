import { DEFAULT_ALERT_TITLES, ALERT_TYPES } from '../../constants/alert_types';
import { buffer } from '../serialization_helpers';
import { getAlertType } from './alert';

const alertTitle = (state, node) => {
  let noteTitle = '';
  const type = getAlertType() || ALERT_TYPES.NOTE;
  if (DEFAULT_ALERT_TITLES[type]) noteTitle += `[!${type}]`;

  const title = buffer(state, () => state.renderInline(node));
  if (title && title !== DEFAULT_ALERT_TITLES[type]) noteTitle += ` ${title.trim()}`;

  state.text(noteTitle, false);
  state.closeBlock(node);
};

export default alertTitle;
