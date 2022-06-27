import { s__ } from '~/locale';

export const COLOR_WIDGET_COLOR = s__('ColorWidget|Color');

export const DROPDOWN_VARIANT = {
  Sidebar: 'sidebar',
  Embedded: 'embedded',
};

export const DEFAULT_COLOR = { title: s__('SuggestedColors|Blue'), color: '#1068bf' };

export const ISSUABLE_COLORS = [
  DEFAULT_COLOR,
  {
    title: s__('SuggestedColors|Green'),
    color: '#217645',
  },
  {
    title: s__('SuggestedColors|Red'),
    color: '#c91c00',
  },
  {
    title: s__('SuggestedColors|Orange'),
    color: '#9e5400',
  },
  {
    title: s__('SuggestedColors|Purple'),
    color: '#694cc0',
  },
];
