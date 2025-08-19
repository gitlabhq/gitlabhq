import Vue from 'vue';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { createDraft } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

Vue.use(PiniaVuePlugin);

describe('Batch comments draft preview item component', () => {
  let wrapper;
  let pinia;
  let draft;

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
  });

  function createComponent(extra = {}, improvedReviewExperience = false) {
    draft = {
      ...createDraft(),
      ...extra,
    };

    wrapper = mountExtended(PreviewItem, {
      pinia,
      propsData: { draft },
      provide: {
        glFeatures: { improvedReviewExperience },
      },
    });
  }

  const findTitle = () => wrapper.findByTestId('review-preview-item-header-text');
  const findContent = () => wrapper.findByTestId('review-preview-item-content');
  const findDraftResolution = () => wrapper.findByTestId('draft-note-resolution');

  it('renders text content', () => {
    createComponent({ note_html: '<img src="" /><p>Hello world</p>' });

    expect(findContent().element.innerHTML).toContain('Hello world');
  });

  describe('for file', () => {
    it('renders file path', () => {
      createComponent({ file_path: 'index.js', file_hash: 'abc', position: {} });

      expect(findTitle().text()).toContain('index.js');
    });

    it('renders new line position', () => {
      createComponent({
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
      expect(wrapper.text()).toContain(':+1');
    });

    it('renders old line position', () => {
      createComponent({
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

      expect(wrapper.text()).toContain(':2');
    });

    it('renders image position', () => {
      createComponent({
        file_path: 'index.js',
        file_hash: 'abc',
        position: { position_type: 'image', x: 10, y: 20 },
      });

      expect(wrapper.text()).toContain('10x 20y');
    });
  });

  describe('for thread', () => {
    beforeEach(() => {
      useNotes().discussions = [
        {
          id: '1',
          notes: [
            {
              author: {
                name: "Author 'Nick' Name",
              },
            },
          ],
        },
      ];

      createComponent({ discussion_id: '1', resolve_discussion: true });
    });

    it('renders title', () => {
      expect(findTitle().text()).toContain("Author 'Nick' Name's thread");
    });

    it('renders thread resolved text', () => {
      expect(findDraftResolution().text()).toContain('Thread will be resolved');
    });
  });

  describe('for new comment', () => {
    it('renders title', () => {
      createComponent();

      expect(findTitle().text()).toContain('Your new comment');
    });
  });
});
