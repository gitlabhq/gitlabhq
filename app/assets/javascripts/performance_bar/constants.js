import { s__ } from '~/locale';

export const sortOrders = {
  DURATION: 'duration',
  CHRONOLOGICAL: 'chronological',
};

export const sortOrderOptions = [
  {
    value: sortOrders.DURATION,
    text: s__('PerformanceBar|Sort by duration'),
  },
  {
    value: sortOrders.CHRONOLOGICAL,
    text: s__('PerformanceBar|Sort chronologically'),
  },
];
