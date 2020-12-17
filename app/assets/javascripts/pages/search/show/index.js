import Search from './search';
import { initSearchApp } from '~/search';

document.addEventListener('DOMContentLoaded', () => {
  initSearchApp(); // Vue Bootstrap
  return new Search(); // Legacy Search Methods
});
