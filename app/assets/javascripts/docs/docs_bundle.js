import Mousetrap from 'mousetrap';

function addMousetrapClick(el, key) {
  el.addEventListener('click', () => Mousetrap.trigger(key));
}

export default () => {
  addMousetrapClick(document.querySelector('.js-trigger-shortcut'), '?');
  addMousetrapClick(document.querySelector('.js-trigger-search-bar'), 's');
};
