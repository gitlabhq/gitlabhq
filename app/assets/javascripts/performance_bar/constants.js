import { s__ } from '~/locale';

export const sortOrders = {
  DURATION: 'duration',
  CHRONOLOGICAL: 'chronological',
};

export const sortOrderOptions = {
  [sortOrders.DURATION]: s__('PerformanceBar|Sort by duration'),
  [sortOrders.CHRONOLOGICAL]: s__('PerformanceBar|Sort chronologically'),
};
