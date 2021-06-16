import Vue from 'vue';
import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import { createStore } from '~/batch_comments/stores';
import diffsModule from '~/diffs/store/modules';
import notesModule from '~/notes/stores/modules';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

describe('Batch comments draft preview item component', () => {
  let vm;
  let Component;
  let draft;

  function createComponent(isLast = false, extra = {}, extendStore = () => {}) {
    const store = createStore();
    store.registerModule('diffs', diffsModule());
    store.registerModule('notes', notesModule());

    extendStore(store);

    draft = {
      ...createDraft(),
      ...extra,
    };

    vm = mountComponentWithStore(Component, { store, props: { draft, isLast } });
  }

  beforeAll(() => {
    Component = Vue.extend(PreviewItem);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders text content', () => {
    createComponent(false, { note_html: '<img src="" /><p>Hello world</p>' });

    expect(vm.$el.querySelector('.review-preview-item-content').innerHTML).toEqual(
      '<p>Hello world</p>',
    );
  });

  describe('for file', () => {
    it('renders file path', () => {
      createComponent(false, { file_path: 'index.js', file_hash: 'abc', position: {} });

      expect(vm.$el.querySelector('.review-preview-item-header-text').textContent).toContain(
        'index.js',
      );
    });

    it('renders new line position', () => {
      createComponent(false, {
        file_path: 'index.js',
        file_hash: 'abc',
        position: {
          line_range: {
            start: {
              new_line: 1,
              type: 'new',
            },
          },
        },
      });

      expect(vm.$el.querySelector('.bold').textContent).toContain(':+1');
    });

    it('renders old line position', () => {
      createComponent(false, {
        file_path: 'index.js',
        file_hash: 'abc',
        position: {
          line_range: {
            start: {
              old_line: 2,
            },
          },
        },
      });

      expect(vm.$el.querySelector('.bold').textContent).toContain(':2');
    });

    it('renders image position', () => {
      createComponent(false, {
        file_path: 'index.js',
        file_hash: 'abc',
        position: { position_type: 'image', x: 10, y: 20 },
      });

      expect(vm.$el.querySelector('.bold').textContent).toContain('10x 20y');
    });
  });

  describe('for thread', () => {
    beforeEach(() => {
      createComponent(false, { discussion_id: '1', resolve_discussion: true }, (store) => {
        store.state.notes.discussions.push({
          id: '1',
          notes: [
            {
              author: {
                name: "Author 'Nick' Name",
              },
            },
          ],
        });
      });
    });

    it('renders title', () => {
      expect(vm.$el.querySelector('.review-preview-item-header-text').textContent).toContain(
        "Author 'Nick' Name's thread",
      );
    });

    it('it renders thread resolved text', () => {
      expect(vm.$el.querySelector('.draft-note-resolution').textContent).toContain(
        'Thread will be resolved',
      );
    });
  });

  describe('for new comment', () => {
    it('renders title', () => {
      createComponent(false, {}, (store) => {
        store.state.notes.discussions.push({});
      });

      expect(vm.$el.querySelector('.review-preview-item-header-text').textContent).toContain(
        'Your new comment',
      );
    });
  });
});
