import white from './white';
import dark from './dark';
import monokai from './monokai';
import solarizedLight from './solarized_light';
import solarizedDark from './solarized_dark';
import none from './none';

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
    name: 'solarized-light',
    data: solarizedLight,
  },
  {
    name: 'solarized-dark',
    data: solarizedDark,
  },
  {
    name: 'monokai',
    data: monokai,
  },
  {
    name: 'none',
    data: none,
  },
];

export const DEFAULT_THEME = 'white';
