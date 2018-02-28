import Vue from 'vue';
import eventHub from './event_hub';
import issuableApp from './components/app.vue';
import '../vue_shared/vue_resource_interceptor';

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
        ...initialData,
      };
    },
    render(createElement) {
      return createElement('issuable-app', {
        props: {
          canUpdate: this.canUpdate,
          canDestroy: this.canDestroy,
          endpoint: this.endpoint,
          issuableRef: this.issuableRef,
          initialTitleHtml: this.initialTitleHtml,
          initialTitleText: this.initialTitleText,
          initialDescriptionHtml: this.initialDescriptionHtml,
          initialDescriptionText: this.initialDescriptionText,
          issuableTemplates: this.issuableTemplates,
          markdownPreviewPath: this.markdownPreviewPath,
          markdownDocsPath: this.markdownDocsPath,
          projectPath: this.projectPath,
          projectNamespace: this.projectNamespace,
          updatedAt: this.updatedAt,
          updatedByName: this.updatedByName,
          updatedByPath: this.updatedByPath,
          initialTaskStatus: this.initialTaskStatus,
        },
      });
    },
  });
});
