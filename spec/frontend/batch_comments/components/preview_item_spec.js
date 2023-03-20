import { mount } from '@vue/test-utils';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import { createStore } from '~/batch_comments/stores';
import diffsModule from '~/diffs/store/modules';
import notesModule from '~/notes/stores/modules';
import { createDraft } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Batch comments draft preview item component', () => {
  let wrapper;
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

    wrapper = mount(PreviewItem, { store, propsData: { draft, isLast } });
  }

  it('renders text content', () => {
    createComponent(false, { note_html: '<img src="" /><p>Hello world</p>' });

    expect(wrapper.find('.review-preview-item-content').element.innerHTML).toBe(
      '<p>Hello world</p>',
    );
  });

  describe('for file', () => {
    it('renders file path', () => {
      createComponent(false, { file_path: 'index.js', file_hash: 'abc', position: {} });

      expect(wrapper.find('.review-preview-item-header-text').text()).toContain('index.js');
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

      expect(wrapper.find('.bold').text()).toContain(':+1');
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

      expect(wrapper.find('.bold').text()).toContain(':2');
    });

    it('renders image position', () => {
      createComponent(false, {
        file_path: 'index.js',
        file_hash: 'abc',
        position: { position_type: 'image', x: 10, y: 20 },
      });

      expect(wrapper.find('.bold').text()).toContain('10x 20y');
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
      expect(wrapper.find('.review-preview-item-header-text').text()).toContain(
        "Author 'Nick' Name's thread",
      );
    });

    it('renders thread resolved text', () => {
      expect(wrapper.find('.draft-note-resolution').text()).toContain('Thread will be resolved');
    });
  });

  describe('for new comment', () => {
    it('renders title', () => {
      createComponent(false, {}, (store) => {
        store.state.notes.discussions.push({});
      });

      expect(wrapper.find('.review-preview-item-header-text').text()).toContain('Your new comment');
    });
  });
});
