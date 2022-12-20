import Vue from 'vue';
import BroadcastMessagesBase from './components/base.vue';

export default () => {
  const el = document.querySelector('#js-broadcast-messages');
  const { page, targetAccessLevelOptions, messagesCount, messages } = el.dataset;

  return new Vue({
    el,
    name: 'BroadcastMessages',
    provide: {
      targetAccessLevelOptions: JSON.parse(targetAccessLevelOptions),
    },
    render(createElement) {
      return createElement(BroadcastMessagesBase, {
        props: {
          page: Number(page),
          messagesCount: Number(messagesCount),
          messages: JSON.parse(messages),
        },
      });
    },
  });
};
