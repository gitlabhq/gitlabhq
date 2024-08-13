import { times } from 'lodash';
import { nextTick } from 'vue';
import { GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SnippetBlobActionsEdit from '~/snippets/components/snippet_blob_actions_edit.vue';
import SnippetBlobEdit from '~/snippets/components/snippet_blob_edit.vue';
import {
  SNIPPET_MAX_BLOBS,
  SNIPPET_BLOB_ACTION_CREATE,
  SNIPPET_BLOB_ACTION_MOVE,
  SNIPPET_LIMITATIONS,
} from '~/snippets/constants';
import { sprintf } from '~/locale';
import { testEntries, createBlobFromTestEntry } from '../test_utils';

const TEST_BLOBS = [
  createBlobFromTestEntry(testEntries.updated),
  createBlobFromTestEntry(testEntries.deleted),
];

const TEST_BLOBS_UNLOADED = TEST_BLOBS.map((blob) => ({ ...blob, content: '', isLoaded: false }));

describe('snippets/components/snippet_blob_actions_edit', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SnippetBlobActionsEdit, {
      propsData: {
        initBlobs: TEST_BLOBS,
        ...props,
      },
    });
  };

  const findLabel = () => wrapper.findComponent(GlFormGroup);
  const findBlobEdits = () => wrapper.findAllComponents(SnippetBlobEdit);
  const findBlobsData = () =>
    findBlobEdits().wrappers.map((x) => ({
      blob: x.props('blob'),
      classes: x.classes(),
    }));
  const findFirstBlobEdit = () => findBlobEdits().at(0);
  const findAddButton = () => wrapper.find('[data-testid="add-button"]');
  const findLimitationsText = () => wrapper.find('[data-testid="limitations_text"]');
  const getLastActions = () => {
    const events = wrapper.emitted().actions;

    return events[events.length - 1]?.[0];
  };
  const buildBlobsDataExpectation = (blobs) =>
    blobs.map((blob, index) => ({
      blob: {
        ...blob,
        id: expect.stringMatching('blob_local_'),
      },
      classes: index > 0 ? ['gl-mt-3'] : [],
    }));
  const triggerBlobDelete = (idx) => findBlobEdits().at(idx).vm.$emit('delete');
  const triggerBlobUpdate = (idx, props) => findBlobEdits().at(idx).vm.$emit('blob-updated', props);

  describe('multi-file snippets rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders label', () => {
      expect(findLabel().attributes('label')).toBe('Files');
    });

    it(`renders delete button (show=true)`, () => {
      expect(findFirstBlobEdit().props()).toMatchObject({
        showDelete: true,
        canDelete: true,
      });
    });

    it(`renders add button (show=true)`, () => {
      expect(findAddButton().exists()).toBe(true);
    });
  });

  describe('with default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits no actions', () => {
      expect(getLastActions()).toEqual([]);
    });

    it('shows blobs', () => {
      expect(findBlobsData()).toEqual(buildBlobsDataExpectation(TEST_BLOBS_UNLOADED));
    });

    it('shows add button', () => {
      const button = findAddButton();

      expect(button.text()).toBe(`Add another file ${TEST_BLOBS.length}/${SNIPPET_MAX_BLOBS}`);
      expect(button.props('disabled')).toBe(false);
    });

    it('do not show limitations text', () => {
      expect(findLimitationsText().exists()).toBe(false);
    });

    describe('when add is clicked', () => {
      beforeEach(() => {
        findAddButton().vm.$emit('click');
      });

      it('adds blob with empty content', () => {
        expect(findBlobsData()).toEqual(
          buildBlobsDataExpectation([
            ...TEST_BLOBS_UNLOADED,
            {
              content: '',
              isLoaded: true,
              path: '',
            },
          ]),
        );
      });

      it('emits action', () => {
        expect(getLastActions()).toEqual([
          expect.objectContaining({
            action: SNIPPET_BLOB_ACTION_CREATE,
          }),
        ]);
      });
    });

    describe('when blob is deleted', () => {
      beforeEach(() => {
        triggerBlobDelete(1);
      });

      it('removes blob', () => {
        expect(findBlobsData()).toEqual(buildBlobsDataExpectation(TEST_BLOBS_UNLOADED.slice(0, 1)));
      });

      it('emits action', () => {
        expect(getLastActions()).toEqual([
          expect.objectContaining({
            ...testEntries.deleted.diff,
            content: '',
          }),
        ]);
      });
    });

    describe('when blob changes path', () => {
      beforeEach(() => {
        triggerBlobUpdate(0, { path: 'new/path' });
      });

      it('renames blob', () => {
        expect(findBlobsData()[0]).toMatchObject({
          blob: {
            path: 'new/path',
          },
        });
      });

      it('emits action', () => {
        expect(getLastActions()).toMatchObject([
          {
            action: SNIPPET_BLOB_ACTION_MOVE,
            filePath: 'new/path',
            previousPath: testEntries.updated.diff.filePath,
          },
        ]);
      });
    });

    describe('when blob emits new content', () => {
      const { content } = testEntries.updated.diff;
      const originalContent = `${content}\noriginal content\n`;

      beforeEach(() => {
        triggerBlobUpdate(0, { content: originalContent });
      });

      it('loads new content', () => {
        expect(findBlobsData()[0]).toMatchObject({
          blob: {
            content: originalContent,
            isLoaded: true,
          },
        });
      });

      it('does not emit an action', () => {
        expect(getLastActions()).toEqual([]);
      });

      it('emits an action when content changes again', async () => {
        triggerBlobUpdate(0, { content });

        await nextTick();

        expect(getLastActions()).toEqual([testEntries.updated.diff]);
      });
    });
  });

  describe('with 1 blob', () => {
    beforeEach(() => {
      createComponent({ initBlobs: [createBlobFromTestEntry(testEntries.created)] });
    });

    it('disables delete button', () => {
      expect(findBlobEdits()).toHaveLength(1);
      expect(findBlobEdits().at(0).props()).toMatchObject({
        showDelete: true,
        canDelete: false,
      });
    });

    describe(`when added ${SNIPPET_MAX_BLOBS} files`, () => {
      let addButton;

      beforeEach(() => {
        addButton = findAddButton();

        times(SNIPPET_MAX_BLOBS - 1, () => addButton.vm.$emit('click'));
      });

      it('should have blobs', () => {
        expect(findBlobsData()).toHaveLength(SNIPPET_MAX_BLOBS);
      });

      it('should disable add button', () => {
        expect(addButton.props('disabled')).toBe(true);
      });
    });
  });

  describe('with 0 init blob', () => {
    beforeEach(() => {
      createComponent({ initBlobs: [] });
    });

    it('shows 1 blob by default', () => {
      expect(findBlobsData()).toEqual([
        expect.objectContaining({
          blob: {
            id: expect.stringMatching('blob_local_'),
            content: '',
            path: '',
            isLoaded: true,
          },
        }),
      ]);
    });

    it('emits create action', () => {
      expect(getLastActions()).toEqual([
        {
          action: SNIPPET_BLOB_ACTION_CREATE,
          content: '',
          filePath: '',
          previousPath: '',
        },
      ]);
    });
  });

  describe(`with ${SNIPPET_MAX_BLOBS} files`, () => {
    beforeEach(() => {
      const initBlobs = Array(SNIPPET_MAX_BLOBS)
        .fill(1)
        .map(() => createBlobFromTestEntry(testEntries.created));

      createComponent({ initBlobs });
    });

    it('should have blobs', () => {
      expect(findBlobsData()).toHaveLength(SNIPPET_MAX_BLOBS);
    });

    it('should disable add button', () => {
      expect(findAddButton().props('disabled')).toBe(true);
    });

    it('shows limitations text', () => {
      expect(findLimitationsText().text()).toBe(
        sprintf(SNIPPET_LIMITATIONS, { total: SNIPPET_MAX_BLOBS }),
      );
    });
  });

  describe('isValid prop', () => {
    const validationMessage =
      "Snippets can't contain empty files. Ensure all files have content, or delete them.";

    describe('when not present', () => {
      it('sets the label validation state to true', () => {
        createComponent();

        const label = findLabel();

        expect(Boolean(label.attributes('state'))).toEqual(true);
        expect(label.attributes('invalid-feedback')).toEqual(validationMessage);
      });
    });

    describe('when present', () => {
      it('sets the label validation state to the value', () => {
        createComponent({ isValid: false });

        const label = findLabel();

        expect(Boolean(label.attributes('state'))).toEqual(false);
        expect(label.attributes('invalid-feedback')).toEqual(validationMessage);
      });
    });
  });
});
