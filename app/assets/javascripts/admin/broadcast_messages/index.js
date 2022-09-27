import Vue from 'vue';
import BroadcastMessagesBase from './components/base.vue';

export default () => {
  const el = document.querySelector('#js-broadcast-messages');
  const { messages } = el.dataset;

  return new Vue({
    el,
    name: 'BroadcastMessagesBase',
    render(createElement) {
      return createElement(BroadcastMessagesBase, {
        props: {
          messages: JSON.parse(messages),
        },
      });
    },
  });
};
