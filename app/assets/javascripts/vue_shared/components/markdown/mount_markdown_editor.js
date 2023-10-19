import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createApolloClient from '~/lib/graphql';
import { queryToObject, objectToQuery } from '~/lib/utils/url_utility';
import { parseBoolean } from '~/lib/utils/common_utils';

import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '../../constants';
import MarkdownEditor from './markdown_editor.vue';
import eventHub from './eventhub';

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

function mountAutosaveClearOnSubmit(autosaveKey) {
  const resetAutosaveButtons = document.querySelectorAll('.js-reset-autosave');
  if (resetAutosaveButtons.length === 0) {
    return;
  }

  for (const resetAutosaveButton of resetAutosaveButtons) {
    resetAutosaveButton.addEventListener('click', () => {
      eventHub.$emit(CLEAR_AUTOSAVE_ENTRY_EVENT, autosaveKey);
    });
  }
}

export function mountMarkdownEditor(options = {}) {
  const el = document.querySelector('.js-markdown-editor');
  const componentConfiguration = {
    provide: {
      ...options.provide,
    },
  };

  if (!el) {
    return null;
  }

  const {
    renderMarkdownPath,
    markdownDocsPath,
    quickActionsDocsPath,
    formFieldPlaceholder,
    formFieldClasses,
    testid,
    newIssuePath,
  } = el.dataset;

  const supportsQuickActions = parseBoolean(el.dataset.supportsQuickActions ?? true);
  const enableAutocomplete = parseBoolean(el.dataset.enableAutocomplete ?? true);
  const disableAttachments = parseBoolean(el.dataset.disableAttachments ?? false);
  const autofocus = parseBoolean(el.dataset.autofocus ?? true);
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
  const autosaveKey = `autosave/${document.location.pathname}/${searchTerm}/description`;

  componentConfiguration.apolloProvider =
    options.apolloProvider || new VueApollo({ defaultClient: createApolloClient() });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(h) {
      return h(MarkdownEditor, {
        props: {
          setFacade,
          value: formFieldValue,
          renderMarkdownPath,
          markdownDocsPath,
          quickActionsDocsPath,
          formFieldProps: {
            placeholder: formFieldPlaceholder,
            id: formFieldId,
            name: formFieldName,
            class: formFieldClasses,
            'data-testid': testid,
          },
          autosaveKey,
          enableAutocomplete,
          autocompleteDataSources: gl.GfmAutoComplete?.dataSources,
          supportsQuickActions,
          disableAttachments,
          autofocus,
        },
      });
    },
    ...componentConfiguration,
  });

  mountAutosaveClearOnSubmit(autosaveKey);

  return facade;
}
