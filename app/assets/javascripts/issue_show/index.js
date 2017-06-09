import Vue from 'vue';
import eventHub from './event_hub';
import issuableApp from './components/app.vue';
import '../vue_shared/vue_resource_interceptor';

<<<<<<< HEAD
(() => {
  const issueTitleData = document.querySelector('.issue-title-data').dataset;
  const initialTitle = document.querySelector('.js-issue-title').innerHTML;
  const initialDescription = document.querySelector('.js-issue-description');
  const { canUpdateTasksClass, endpoint, isEdited } = issueTitleData;

  const vm = new Vue({
    el: '.issue-title-entrypoint',
    render: createElement => createElement(IssueTitle, {
      props: {
        canUpdateTasksClass,
        endpoint,
        isEdited,
        initialTitle,
        initialDescription: initialDescription ? initialDescription.innerHTML : '',
      },
    }),
=======
document.addEventListener('DOMContentLoaded', () => {
  const initialDataEl = document.getElementById('js-issuable-app-initial-data');
  const initialData = JSON.parse(initialDataEl.innerHTML.replace(/&quot;/g, '"'));

  $('.issuable-edit').on('click', (e) => {
    e.preventDefault();

    eventHub.$emit('open.form');
>>>>>>> abc61f260074663e5711d3814d9b7d301d07a259
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
