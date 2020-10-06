import '~/snippet/snippet_edit';
import { triggerDOMEvent } from 'jest/helpers/dom_events_helper';
import { SnippetEditInit } from '~/snippets';

jest.mock('~/snippets');
jest.mock('~/gl_form');

describe('Snippet edit form initialization', () => {
  beforeEach(() => {
    setFixtures('<div class="snippet-form"></div>');
  });

  it('correctly initializes Vue Snippet Edit form', () => {
    SnippetEditInit.mockClear();

    triggerDOMEvent('DOMContentLoaded');

    expect(SnippetEditInit).toHaveBeenCalled();
  });
});
