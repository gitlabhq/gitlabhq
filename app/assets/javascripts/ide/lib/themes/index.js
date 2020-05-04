import white from './white';
import dark from './dark';
import monokai from './monokai';
import solarizedDark from './solarized_dark';

export const themes = [
  {
    name: 'white',
    data: white,
  },
  {
    name: 'dark',
    data: dark,
  },
  {
    name: 'solarized-dark',
    data: solarizedDark,
  },
  {
    name: 'monokai',
    data: monokai,
  },
];

export const DEFAULT_THEME = 'white';
