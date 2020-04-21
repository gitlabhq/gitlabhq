import '~/snippet/snippet_edit';
import { SnippetEditInit } from '~/snippets';
import initSnippet from '~/snippet/snippet_bundle';

import { triggerDOMEvent } from 'jest/helpers/dom_events_helper';

jest.mock('~/snippet/snippet_bundle');
jest.mock('~/snippets');

describe('Snippet edit form initialization', () => {
  const setFF = flag => {
    gon.features = { snippetsEditVue: flag };
  };
  let features;

  beforeEach(() => {
    features = gon.features;
    setFixtures('<div class="snippet-form"></div>');
  });

  afterEach(() => {
    gon.features = features;
  });

  it.each`
    name         | flag     | isVue
    ${'Regular'} | ${false} | ${false}
    ${'Vue'}     | ${true}  | ${true}
  `('correctly initializes $name Snippet Edit form', ({ flag, isVue }) => {
    initSnippet.mockClear();
    SnippetEditInit.mockClear();

    setFF(flag);

    triggerDOMEvent('DOMContentLoaded');

    if (isVue) {
      expect(initSnippet).not.toHaveBeenCalled();
      expect(SnippetEditInit).toHaveBeenCalled();
    } else {
      expect(initSnippet).toHaveBeenCalled();
      expect(SnippetEditInit).not.toHaveBeenCalled();
    }
  });
});
