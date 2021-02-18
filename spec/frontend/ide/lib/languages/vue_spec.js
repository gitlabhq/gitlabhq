import { editor } from 'monaco-editor';
import vue from '~/ide/lib/languages/vue';
import { registerLanguages } from '~/ide/utils';

// This file only tests syntax specific to vue. This does not test existing syntaxes
// of html, javascript, css and handlebars, which vue files extend.
describe('tokenization for .vue files', () => {
  beforeEach(() => {
    registerLanguages(vue);
  });

  it.each([
    [
      '<div v-if="something">content</div>',
      [
        [
          { language: 'vue', offset: 0, type: 'delimiter.html' },
          { language: 'vue', offset: 1, type: 'tag.html' },
          { language: 'vue', offset: 4, type: '' },
          { language: 'vue', offset: 5, type: 'variable' },
          { language: 'vue', offset: 21, type: 'delimiter.html' },
          { language: 'vue', offset: 22, type: '' },
          { language: 'vue', offset: 29, type: 'delimiter.html' },
          { language: 'vue', offset: 31, type: 'tag.html' },
          { language: 'vue', offset: 34, type: 'delimiter.html' },
        ],
      ],
    ],
    [
      '<input :placeholder="placeholder">',
      [
        [
          { language: 'vue', offset: 0, type: 'delimiter.html' },
          { language: 'vue', offset: 1, type: 'tag.html' },
          { language: 'vue', offset: 6, type: '' },
          { language: 'vue', offset: 7, type: 'variable' },
          { language: 'vue', offset: 33, type: 'delimiter.html' },
        ],
      ],
    ],
    [
      '<gl-modal @ok="submitForm()"></gl-modal>',
      [
        [
          { language: 'vue', offset: 0, type: 'delimiter.html' },
          { language: 'vue', offset: 1, type: 'tag.html' },
          { language: 'vue', offset: 3, type: 'attribute.name' },
          { language: 'vue', offset: 9, type: '' },
          { language: 'vue', offset: 10, type: 'variable' },
          { language: 'vue', offset: 28, type: 'delimiter.html' },
          { language: 'vue', offset: 31, type: 'tag.html' },
          { language: 'vue', offset: 33, type: 'attribute.name' },
          { language: 'vue', offset: 39, type: 'delimiter.html' },
        ],
      ],
    ],
    [
      '<a v-on:click.stop="doSomething">...</a>',
      [
        [
          { language: 'vue', offset: 0, type: 'delimiter.html' },
          { language: 'vue', offset: 1, type: 'tag.html' },
          { language: 'vue', offset: 2, type: '' },
          { language: 'vue', offset: 3, type: 'variable' },
          { language: 'vue', offset: 32, type: 'delimiter.html' },
          { language: 'vue', offset: 33, type: '' },
          { language: 'vue', offset: 36, type: 'delimiter.html' },
          { language: 'vue', offset: 38, type: 'tag.html' },
          { language: 'vue', offset: 39, type: 'delimiter.html' },
        ],
      ],
    ],
    [
      '<a @[event]="doSomething">...</a>',
      [
        [
          { language: 'vue', offset: 0, type: 'delimiter.html' },
          { language: 'vue', offset: 1, type: 'tag.html' },
          { language: 'vue', offset: 2, type: '' },
          { language: 'vue', offset: 3, type: 'variable' },
          { language: 'vue', offset: 25, type: 'delimiter.html' },
          { language: 'vue', offset: 26, type: '' },
          { language: 'vue', offset: 29, type: 'delimiter.html' },
          { language: 'vue', offset: 31, type: 'tag.html' },
          { language: 'vue', offset: 32, type: 'delimiter.html' },
        ],
      ],
    ],
  ])('%s', (string, tokens) => {
    expect(editor.tokenize(string, 'vue')).toEqual(tokens);
  });
});
