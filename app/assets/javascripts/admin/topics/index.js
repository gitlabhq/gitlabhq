import Vue from 'vue';
import RemoveAvatar from './components/remove_avatar.vue';

export default () => {
  const el = document.querySelector('.js-remove-topic-avatar');

  if (!el) {
    return false;
  }

  const { path, name } = el.dataset;

  return new Vue({
    el,
    provide: {
      path,
      name,
    },
    render(h) {
      return h(RemoveAvatar);
    },
  });
};
