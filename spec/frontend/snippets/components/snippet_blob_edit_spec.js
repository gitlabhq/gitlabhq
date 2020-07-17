import SnippetBlobEdit from '~/snippets/components/snippet_blob_edit.vue';
import BlobHeaderEdit from '~/blob/components/blob_edit_header.vue';
import BlobContentEdit from '~/blob/components/blob_edit_content.vue';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/blob/utils', () => jest.fn());

jest.mock('~/lib/utils/url_utility', () => ({
  getBaseURL: jest.fn().mockReturnValue('foo/'),
  joinPaths: jest
    .fn()
    .mockName('joinPaths')
    .mockReturnValue('contentApiURL'),
}));

jest.mock('~/flash');

let flashSpy;

describe('Snippet Blob Edit component', () => {
  let wrapper;
  let axiosMock;
  const contentMock = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const pathMock = 'lorem.txt';
  const rawPathMock = 'foo/bar';
  const blob = {
    path: pathMock,
    content: contentMock,
    rawPath: rawPathMock,
  };
  const findComponent = component => wrapper.find(component);

  function createComponent(props = {}, data = { isContentLoading: false }) {
    wrapper = shallowMount(SnippetBlobEdit, {
      propsData: {
        ...props,
      },
      data() {
        return {
          ...data,
        };
      },
    });
    flashSpy = jest.spyOn(wrapper.vm, 'flashAPIFailure');
  }

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      createComponent({ blob });
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders required components', () => {
      expect(findComponent(BlobHeaderEdit).exists()).toBe(true);
      expect(findComponent(BlobContentEdit).exists()).toBe(true);
    });

    it('renders loader if existing blob is supplied but no content is fetched yet', () => {
      createComponent({ blob }, { isContentLoading: true });
      expect(wrapper.contains(GlLoadingIcon)).toBe(true);
      expect(findComponent(BlobContentEdit).exists()).toBe(false);
    });

    it('does not render loader if when blob is not supplied', () => {
      createComponent();
      expect(wrapper.contains(GlLoadingIcon)).toBe(false);
      expect(findComponent(BlobContentEdit).exists()).toBe(true);
    });
  });

  describe('functionality', () => {
    it('does not fail without blob', () => {
      const spy = jest.spyOn(global.console, 'error');
      createComponent({ blob: undefined });

      expect(spy).not.toHaveBeenCalled();
      expect(findComponent(BlobContentEdit).exists()).toBe(true);
    });

    it.each`
      emitter            | prop
      ${BlobHeaderEdit}  | ${'filePath'}
      ${BlobContentEdit} | ${'content'}
    `('emits "blob-updated" event when the $prop gets changed', ({ emitter, prop }) => {
      expect(wrapper.emitted('blob-updated')).toBeUndefined();
      const newValue = 'foo.bar';
      findComponent(emitter).vm.$emit('input', newValue);

      return nextTick().then(() => {
        expect(wrapper.emitted('blob-updated')[0]).toEqual([
          expect.objectContaining({
            [prop]: newValue,
          }),
        ]);
      });
    });

    describe('fetching blob content', () => {
      const bootstrapForExistingSnippet = resp => {
        createComponent({
          blob: {
            ...blob,
            content: '',
          },
        });

        if (resp === 500) {
          axiosMock.onGet('contentApiURL').reply(500);
        } else {
          axiosMock.onGet('contentApiURL').reply(200, contentMock);
        }
      };

      const bootstrapForNewSnippet = () => {
        createComponent();
      };

      it('fetches blob content with the additional query', () => {
        bootstrapForExistingSnippet();

        return waitForPromises().then(() => {
          expect(joinPaths).toHaveBeenCalledWith('foo/', rawPathMock);
          expect(findComponent(BlobHeaderEdit).props('value')).toBe(pathMock);
          expect(findComponent(BlobContentEdit).props('value')).toBe(contentMock);
        });
      });

      it('flashes the error message if fetching content fails', () => {
        bootstrapForExistingSnippet(500);

        return waitForPromises().then(() => {
          expect(flashSpy).toHaveBeenCalled();
          expect(findComponent(BlobContentEdit).props('value')).toBe('');
        });
      });

      it('does not fetch content for new snippet', () => {
        bootstrapForNewSnippet();

        return waitForPromises().then(() => {
          // we keep using waitForPromises to make sure we do not run failed test
          expect(findComponent(BlobHeaderEdit).props('value')).toBe('');
          expect(findComponent(BlobContentEdit).props('value')).toBe('');
          expect(joinPaths).not.toHaveBeenCalled();
        });
      });
    });
  });
});
