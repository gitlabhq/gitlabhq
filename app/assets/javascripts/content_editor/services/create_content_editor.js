import { Editor } from '@tiptap/vue-2';
import { isFunction, flatMap } from 'lodash';
import eventHubFactory from '~/helpers/event_hub_factory';
import { PROVIDE_SERIALIZER_OR_RENDERER_ERROR } from '../constants';
import * as builtInExtensions from '../extensions';
import { ContentEditor } from './content_editor';
import MarkdownSerializer from './markdown_serializer';
import createGlApiMarkdownDeserializer from './gl_api_markdown_deserializer';
import AssetResolver from './asset_resolver';
import trackInputRulesAndShortcuts from './track_input_rules_and_shortcuts';
import AutocompleteHelper from './autocomplete_helper';

const createTiptapEditor = ({ extensions = [], ...options } = {}) =>
  new Editor({
    extensions: [...extensions],
    ...options,
  });

export const createContentEditor = ({
  renderMarkdown,
  uploadsPath,
  extensions = [],
  serializerConfig = { marks: {}, nodes: {} },
  tiptapOptions,
  drawioEnabled = false,
  enableAutocomplete,
  autocompleteDataSources = {},
  sidebarMediator = {},
  codeSuggestionsConfig = {},
} = {}) => {
  if (!isFunction(renderMarkdown)) {
    throw new Error(PROVIDE_SERIALIZER_OR_RENDERER_ERROR);
  }

  const eventHub = eventHubFactory();
  const assetResolver = new AssetResolver({ renderMarkdown });
  const serializer = new MarkdownSerializer({ serializerConfig });
  const autocompleteHelper = new AutocompleteHelper({
    dataSourceUrls: autocompleteDataSources,
    sidebarMediator,
  });
  const deserializer = createGlApiMarkdownDeserializer({
    render: renderMarkdown,
  });

  const { Suggestions, DrawioDiagram, ...otherExtensions } = builtInExtensions;

  const builtInContentEditorExtensions = flatMap(otherExtensions).map((ext) =>
    ext.configure({
      uploadsPath,
      renderMarkdown,
      eventHub,
      codeSuggestionsConfig,
      serializer,
      assetResolver,
    }),
  );

  const allExtensions = [...builtInContentEditorExtensions, ...extensions];

  if (enableAutocomplete)
    allExtensions.push(Suggestions.configure({ autocompleteHelper, serializer }));
  if (drawioEnabled) allExtensions.push(DrawioDiagram.configure({ uploadsPath, assetResolver }));

  const trackedExtensions = allExtensions.map(trackInputRulesAndShortcuts);
  const tiptapEditor = createTiptapEditor({ extensions: trackedExtensions, ...tiptapOptions });

  return new ContentEditor({
    tiptapEditor,
    serializer,
    eventHub,
    deserializer,
    assetResolver,
    drawioEnabled,
    codeSuggestionsConfig,
    autocompleteHelper,
  });
};
