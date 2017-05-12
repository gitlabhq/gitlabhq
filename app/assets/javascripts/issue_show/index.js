import Vue from 'vue';
import eventHub from './event_hub';
import issuableApp from './components/app.vue';
import '../vue_shared/vue_resource_interceptor';

document.addEventListener('DOMContentLoaded', () => {
  $('.issuable-edit').on('click', (e) => {
    e.preventDefault();

    eventHub.$emit('open.form');
  });

  return new Vue({
    el: document.getElementById('js-issuable-app'),
    components: {
      issuableApp,
    },
    data() {
      const issuableElement = this.$options.el;
      const issuableTitleElement = issuableElement.querySelector('.title');
      const issuableDescriptionElement = issuableElement.querySelector('.wiki');
      const issuableDescriptionTextarea = issuableElement.querySelector('.js-task-list-field');
      const {
        canUpdate,
        canDestroy,
        endpoint,
        issuableRef,
        markdownPreviewUrl,
      } = issuableElement.dataset;

      return {
        canUpdate: gl.utils.convertPermissionToBoolean(canUpdate),
        canDestroy: gl.utils.convertPermissionToBoolean(canDestroy),
        endpoint,
        issuableRef,
        initialTitle: issuableTitleElement.innerHTML,
        initialDescriptionHtml: issuableDescriptionElement ? issuableDescriptionElement.innerHTML : '',
        initialDescriptionText: issuableDescriptionTextarea ? issuableDescriptionTextarea.textContent : '',
        markdownPreviewUrl,
      };
    },
    render(createElement) {
      return createElement('issuable-app', {
        props: {
          canUpdate: this.canUpdate,
          canDestroy: this.canDestroy,
          endpoint: this.endpoint,
          issuableRef: this.issuableRef,
          initialTitle: this.initialTitle,
          initialDescriptionHtml: this.initialDescriptionHtml,
          initialDescriptionText: this.initialDescriptionText,
          markdownPreviewUrl: this.markdownPreviewUrl,
        },
      });
    },
  });
});
