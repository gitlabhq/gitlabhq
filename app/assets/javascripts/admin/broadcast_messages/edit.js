import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import MessageForm from './components/message_form.vue';

export default () => {
  const el = document.querySelector('#js-broadcast-message');
  const {
    id,
    message,
    broadcastType,
    theme,
    dismissable,
    targetAccessLevels,
    targetAccessLevelOptions,
    messagesPath,
    previewPath,
    targetPath,
    startsAt,
    endsAt,
    showInCli,
  } = el.dataset;

  return new Vue({
    el,
    name: 'EditBroadcastMessage',
    provide: {
      targetAccessLevelOptions: JSON.parse(targetAccessLevelOptions),
      messagesPath,
      previewPath,
    },
    render(createElement) {
      return createElement(MessageForm, {
        props: {
          broadcastMessage: {
            id: parseInt(id, 10),
            message,
            broadcastType,
            theme,
            dismissable: parseBoolean(dismissable),
            targetAccessLevels: JSON.parse(targetAccessLevels),
            targetPath,
            startsAt: new Date(startsAt),
            endsAt: new Date(endsAt),
            showInCli: parseBoolean(showInCli),
          },
        },
      });
    },
  });
};
