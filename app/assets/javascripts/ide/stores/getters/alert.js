import { findAlertKeyToShow } from '../../lib/alerts';

export const getAlert = (state) => (file) => findAlertKeyToShow(state, file);
