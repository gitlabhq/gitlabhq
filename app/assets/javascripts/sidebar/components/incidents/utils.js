import { s__ } from '~/locale';

import { STATUS_LABELS } from './constants';

export const getStatusLabel = (status) => STATUS_LABELS[status] ?? s__('IncidentManagement|None');
