import Search from './search';
import { initSearchApp } from '~/search';

document.addEventListener('DOMContentLoaded', () => {
  initSearchApp();
  return new Search(); // Deprecated Dropdown (Projects)
});
