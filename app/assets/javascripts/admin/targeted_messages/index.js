import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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
    roleOptions,
    initialRoles,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'TargetedMessageFormRoot',
    component: TargetedMessageForm,
    props: {
      targetTypes: JSON.parse(targetTypes),
      formAction,
      isAddForm: isAddForm === 'true',
      initialTargetType,
      initialStartsAt,
      initialEndsAt,
      maxNamespaceIds: parseInt(maxNamespaceIds, 10),
      messagesPath,
      roleOptions: JSON.parse(roleOptions || '[]'),
      initialRoles: JSON.parse(initialRoles || '[]'),
    },
  });
};
