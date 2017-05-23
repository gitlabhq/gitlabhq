import Vue from 'vue';
import eventHub from './event_hub';
import issuableApp from './components/app.vue';
import '../vue_shared/vue_resource_interceptor';

<<<<<<< HEAD
document.addEventListener('DOMContentLoaded', () => {
  const initialDataEl = document.getElementById('js-issuable-app-initial-data');
  const initialData = JSON.parse(initialDataEl.innerHTML.replace(/&quot;/g, '"'));

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
      return {
<<<<<<< HEAD
<<<<<<< HEAD
        ...initialData,
=======
        canUpdate: gl.utils.convertPermissionToBoolean(canUpdate),
        canDestroy: gl.utils.convertPermissionToBoolean(canDestroy),
        canMove: gl.utils.convertPermissionToBoolean(canMove),
        endpoint,
        issuableRef,
        initialTitle: issuableTitleElement.innerHTML,
        initialDescriptionHtml: issuableDescriptionElement ? issuableDescriptionElement.innerHTML : '',
        initialDescriptionText: issuableDescriptionTextarea ? issuableDescriptionTextarea.textContent : '',
        isConfidential: gl.utils.convertPermissionToBoolean(isConfidential),
        markdownPreviewUrl,
        markdownDocs,
        projectPath: initialData.project_path,
        projectNamespace: initialData.namespace_path,
        projectsAutocompleteUrl,
        issuableTemplates: initialData.templates,
>>>>>>> 17617a3... Moved value into computed property
=======
        ...initialData,
>>>>>>> b2c2751... Changed all data to come through the JSON script element
      };
    },
    render(createElement) {
      return createElement('issuable-app', {
        props: {
          canUpdate: this.canUpdate,
          canDestroy: this.canDestroy,
          canMove: this.canMove,
          endpoint: this.endpoint,
          issuableRef: this.issuableRef,
          initialTitleHtml: this.initialTitleHtml,
          initialTitleText: this.initialTitleText,
          initialDescriptionHtml: this.initialDescriptionHtml,
          initialDescriptionText: this.initialDescriptionText,
          issuableTemplates: this.issuableTemplates,
          isConfidential: this.isConfidential,
          markdownPreviewUrl: this.markdownPreviewUrl,
          markdownDocs: this.markdownDocs,
          projectPath: this.projectPath,
          projectNamespace: this.projectNamespace,
          projectsAutocompleteUrl: this.projectsAutocompleteUrl,
          updatedAt: this.updatedAt,
          updatedByName: this.updatedByName,
          updatedByPath: this.updatedByPath,
        },
      });
    },
  });
});
=======
document.addEventListener('DOMContentLoaded', () => new Vue({
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
      endpoint,
      issuableRef,
      updatedAt,
      updatedByName,
      updatedByPath,
    } = issuableElement.dataset;

    return {
      canUpdate: gl.utils.convertPermissionToBoolean(canUpdate),
      endpoint,
      issuableRef,
      initialTitle: issuableTitleElement.innerHTML,
      initialDescriptionHtml: issuableDescriptionElement ? issuableDescriptionElement.innerHTML : '',
      initialDescriptionText: issuableDescriptionTextarea ? issuableDescriptionTextarea.textContent : '',
      updatedAt,
      updatedByName,
      updatedByPath,
    };
  },
  render(createElement) {
    return createElement('issuable-app', {
      props: {
        canUpdate: this.canUpdate,
        endpoint: this.endpoint,
        issuableRef: this.issuableRef,
        initialTitle: this.initialTitle,
        initialDescriptionHtml: this.initialDescriptionHtml,
        initialDescriptionText: this.initialDescriptionText,
        updatedAt: this.updatedAt,
        updatedByName: this.updatedByName,
        updatedByPath: this.updatedByPath,
      },
    });
  },
}));
>>>>>>> 07c984d... Port fix-realtime-edited-text-for-issues 9-2-stable fix to master.
