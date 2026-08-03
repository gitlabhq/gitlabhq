import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import BroadcastMessagesBase from './components/base.vue';

export default () => {
  const el = document.querySelector('#js-broadcast-messages');
  const { page, targetAccessLevelOptions, messagesPath, previewPath, messagesCount, messages } =
    el.dataset;

  return initVueApp({
    el,
    name: 'BroadcastMessages',
    provide: {
      targetAccessLevelOptions: JSON.parse(targetAccessLevelOptions),
      messagesPath,
      previewPath,
    },
    component: BroadcastMessagesBase,
    props: {
      page: Number(page),
      messagesCount: Number(messagesCount),
      messages: JSON.parse(messages),
    },
  });
};
