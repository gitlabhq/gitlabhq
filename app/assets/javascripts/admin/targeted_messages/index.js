import Vue from 'vue';
import TargetedMessageForm from './components/targeted_message_form.vue';

export default () => {
  const el = document.getElementById('js-targeted-message-form');

  if (!el) {
    return null;
  }

  const {
    targetTypes,
    formAction,
    isAddForm,
    initialTargetType,
    initialStartsAt,
    initialEndsAt,
    maxNamespaceIds,
    messagesPath,
  } = el.dataset;

  return new Vue({
    el,
    name: 'TargetedMessageFormRoot',
    render(h) {
      return h(TargetedMessageForm, {
        props: {
          targetTypes: JSON.parse(targetTypes),
          formAction,
          isAddForm: isAddForm === 'true',
          initialTargetType,
          initialStartsAt,
          initialEndsAt,
          maxNamespaceIds: parseInt(maxNamespaceIds, 10),
          messagesPath,
        },
      });
    },
  });
};
