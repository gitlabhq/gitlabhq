import Vue from 'vue';
import { queryToObject, objectToQuery } from '~/lib/utils/url_utility';
import MarkdownEditor from './markdown_editor.vue';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';
const MR_TARGET_BRANCH = 'merge_request[target_branch]';

function organizeQuery(obj, isFallbackKey = false) {
  if (!obj[MR_SOURCE_BRANCH] && !obj[MR_TARGET_BRANCH]) {
    return obj;
  }

  if (isFallbackKey) {
    return {
      [MR_SOURCE_BRANCH]: obj[MR_SOURCE_BRANCH],
    };
  }

  return {
    [MR_SOURCE_BRANCH]: obj[MR_SOURCE_BRANCH],
    [MR_TARGET_BRANCH]: obj[MR_TARGET_BRANCH],
  };
}

function format(searchTerm, isFallbackKey = false) {
  const queryObject = queryToObject(searchTerm, { legacySpacesDecode: true });
  const organizeQueryObject = organizeQuery(queryObject, isFallbackKey);
  const formattedQuery = objectToQuery(organizeQueryObject);

  return formattedQuery;
}

function getSearchTerm(newIssuePath) {
  const { search, pathname } = document.location;
  return newIssuePath === pathname ? '' : format(search);
}

export function mountMarkdownEditor() {
  const el = document.querySelector('.js-markdown-editor');

  if (!el) {
    return null;
  }

  const {
    renderMarkdownPath,
    markdownDocsPath,
    quickActionsDocsPath,
    formFieldPlaceholder,
    formFieldClasses,
    qaSelector,
    newIssuePath,
  } = el.dataset;

  const hiddenInput = el.querySelector('input[type="hidden"]');
  const formFieldName = hiddenInput.getAttribute('name');
  const formFieldId = hiddenInput.getAttribute('id');
  const formFieldValue = hiddenInput.value;

  const searchTerm = getSearchTerm(newIssuePath);
  const facade = {
    setValue() {},
    getValue() {},
    focus() {},
  };

  const setFacade = (props) => Object.assign(facade, props);

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(h) {
      return h(MarkdownEditor, {
        props: {
          setFacade,
          enableContentEditor: Boolean(gon.features?.contentEditorOnIssues),
          value: formFieldValue,
          renderMarkdownPath,
          markdownDocsPath,
          quickActionsDocsPath,
          formFieldProps: {
            placeholder: formFieldPlaceholder,
            id: formFieldId,
            name: formFieldName,
            class: formFieldClasses,
            'data-qa-selector': qaSelector,
          },
          autosaveKey: `autosave/${document.location.pathname}/${searchTerm}/description`,
          enableAutocomplete: true,
          autocompleteDataSources: gl.GfmAutoComplete?.dataSources,
          supportsQuickActions: true,
          autofocus: true,
        },
      });
    },
  });

  return facade;
}
