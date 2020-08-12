import { shallowMount } from '@vue/test-utils';
import SnippetBlobActionsEdit from '~/snippets/components/snippet_blob_actions_edit.vue';
import SnippetBlobEdit from '~/snippets/components/snippet_blob_edit.vue';

const TEST_BLOBS = [
  { name: 'foo', content: 'abc', rawPath: 'test/raw' },
  { name: 'bar', content: 'def', rawPath: 'test/raw' },
];
const TEST_EVENT = 'blob-update';

describe('snippets/components/snippet_blob_actions_edit', () => {
  let onEvent;
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(SnippetBlobActionsEdit, {
      propsData: {
        blobs: [],
        ...props,
      },
      listeners: {
        [TEST_EVENT]: onEvent,
      },
    });
  };
  const findBlobEdit = () => wrapper.find(SnippetBlobEdit);
  const findBlobEditData = () => wrapper.findAll(SnippetBlobEdit).wrappers.map(x => x.props());

  beforeEach(() => {
    onEvent = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    props                    | expectedData
    ${{}}                    | ${[{ blob: null }]}
    ${{ blobs: TEST_BLOBS }} | ${TEST_BLOBS.map(blob => ({ blob }))}
  `('with $props', ({ props, expectedData }) => {
    beforeEach(() => {
      createComponent(props);
    });

    it('renders blob edit', () => {
      expect(findBlobEditData()).toEqual(expectedData);
    });

    it('emits event', () => {
      expect(onEvent).not.toHaveBeenCalled();

      findBlobEdit().vm.$emit('blob-update', TEST_BLOBS[0]);

      expect(onEvent).toHaveBeenCalledWith(TEST_BLOBS[0]);
    });
  });
});
