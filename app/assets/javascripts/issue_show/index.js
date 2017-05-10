import Vue from 'vue';
import issuableApp from './components/app.vue';
import '../vue_shared/vue_resource_interceptor';

document.addEventListener('DOMContentLoaded', () => {
  const issuableElement = document.getElementById('js-issuable-app');
  const issuableTitleElement = issuableElement.querySelector('.title');
  const issuableDescriptionElement = issuableElement.querySelector('.wiki');
  const issuableDescriptionTextarea = issuableElement.querySelector('.js-task-list-field');
  const {
    canUpdate,
    endpoint,
    issuableRef,
  } = issuableElement.dataset;

  return new Vue({
    el: issuableElement,
    components: {
      issuableApp,
    },
    render: createElement => createElement('issuable-app', {
      props: {
        canUpdate: gl.utils.convertPermissionToBoolean(canUpdate),
        endpoint,
        issuableRef,
        initialTitle: issuableTitleElement.innerHTML,
        initialDescriptionHtml: issuableDescriptionElement ? issuableDescriptionElement.innerHTML : '',
        initialDescriptionText: issuableDescriptionTextarea ? issuableDescriptionTextarea.textContent : '',
      },
    }),
  });
});
