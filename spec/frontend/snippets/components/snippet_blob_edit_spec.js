import SnippetBlobEdit from '~/snippets/components/snippet_blob_edit.vue';
import BlobHeaderEdit from '~/blob/components/blob_edit_header.vue';
import BlobContentEdit from '~/blob/components/blob_edit_content.vue';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

jest.mock('~/blob/utils', () => jest.fn());

describe('Snippet Blob Edit component', () => {
  let wrapper;
  const value = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const fileName = 'lorem.txt';
  const findHeader = () => wrapper.find(BlobHeaderEdit);
  const findContent = () => wrapper.find(BlobContentEdit);

  function createComponent(props = {}) {
    wrapper = shallowMount(SnippetBlobEdit, {
      propsData: {
        value,
        fileName,
        isLoading: false,
        ...props,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders required components', () => {
      expect(findHeader().exists()).toBe(true);
      expect(findContent().exists()).toBe(true);
    });

    it('renders loader if isLoading equals true', () => {
      createComponent({ isLoading: true });
      expect(wrapper.contains(GlLoadingIcon)).toBe(true);
      expect(findContent().exists()).toBe(false);
    });
  });

  describe('functionality', () => {
    it('does not fail without content', () => {
      const spy = jest.spyOn(global.console, 'error');
      createComponent({ value: undefined });

      expect(spy).not.toHaveBeenCalled();
      expect(findContent().exists()).toBe(true);
    });

    it('emits "name-change" event when the file name gets changed', () => {
      expect(wrapper.emitted('name-change')).toBeUndefined();
      const newFilename = 'foo.bar';
      findHeader().vm.$emit('input', newFilename);

      return nextTick().then(() => {
        expect(wrapper.emitted('name-change')[0]).toEqual([newFilename]);
      });
    });

    it('emits "input" event when the file content gets changed', () => {
      expect(wrapper.emitted('input')).toBeUndefined();
      const newValue = 'foo.bar';
      findContent().vm.$emit('input', newValue);

      return nextTick().then(() => {
        expect(wrapper.emitted('input')[0]).toEqual([newValue]);
      });
    });
  });
});
