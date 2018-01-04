import Mousetrap from 'mousetrap';

function addMousetrapClick(el, key) {
  el.addEventListener('click', () => Mousetrap.trigger(key));
}

function domContentLoaded() {
  addMousetrapClick(document.querySelector('.js-trigger-shortcut'), '?');
  addMousetrapClick(document.querySelector('.js-trigger-search-bar'), 's');
}

document.addEventListener('DOMContentLoaded', domContentLoaded);

