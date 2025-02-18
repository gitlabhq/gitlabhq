import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobChunks from '~/search/results/components/blob_chunks.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_CLICK_BLOB_RESULT_BLAME_LINE,
  EVENT_CLICK_BLOB_RESULT_LINE,
} from '~/search/results/tracking';
import { mockDataForBlobChunk } from '../../mock_data';

describe('BlobChunks', () => {
  const { bindInternalEventDocument } = useMockInternalEventsTracking();
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(BlobChunks, {
      propsData: {
        ...props,
      },
      stubs: {
        GlLink,
      },
    });
  };

  const findGlIcon = () => wrapper.findAllComponents(GlIcon);
  const findGlLink = () => wrapper.findAllComponents(GlLink);
  const findLine = () => wrapper.findAllByTestId('search-blob-line');
  const findLineNumbers = () => wrapper.findAllByTestId('search-blob-line-numbers');
  const findNonHighlightedLineCode = () =>
    wrapper.findAllByTestId('search-blob-line-code-non-highlighted');
  const findHighlightedLineCode = () =>
    wrapper.findAllByTestId('search-blob-line-code-highlighted');
  const findBlameLink = () =>
    findGlLink().wrappers.filter(
      (w) => w.attributes('data-testid') === 'search-blob-line-blame-link',
    );
  const findLineLink = () =>
    findGlLink().wrappers.filter((w) => w.attributes('data-testid') === 'search-blob-line-link');

  describe('when initial render', () => {
    beforeEach(() => {
      createComponent(mockDataForBlobChunk);
    });

    it('renders default state', () => {
      expect(findLine()).toHaveLength(4);
      expect(findLineNumbers()).toHaveLength(4);
      expect(findNonHighlightedLineCode()).toHaveLength(4);
      expect(findHighlightedLineCode()).toHaveLength(0);
      expect(findGlLink()).toHaveLength(8);
      expect(findGlIcon()).toHaveLength(4);
    });

    it('renders links correctly', () => {
      expect(findGlLink().at(0).attributes('href')).toBe('https://gitlab.com/blame/test.js#L1');
      expect(findGlLink().at(0).attributes('title')).toBe('View blame');
      expect(findGlLink().at(0).findComponent(GlIcon).exists()).toBe(true);
      expect(findGlLink().at(0).findComponent(GlIcon).props('name')).toBe('git');

      expect(findGlLink().at(1).attributes('href')).toBe('https://gitlab.com/file/test.js#L1');
      expect(findGlLink().at(1).attributes('title')).toBe('View line in repository');
      expect(findGlLink().at(1).text()).toBe('1');
    });

    it.each`
      trackedLink      | event
      ${findBlameLink} | ${EVENT_CLICK_BLOB_RESULT_BLAME_LINE}
      ${findLineLink}  | ${EVENT_CLICK_BLOB_RESULT_LINE}
    `('emits $event on click', ({ trackedLink, event }) => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      trackedLink().at(0).vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(event, { property: '1', value: 1 }, undefined);
    });
  });

  describe('when frontend highlighting', () => {
    beforeEach(async () => {
      createComponent(mockDataForBlobChunk);
      await waitForPromises();
    });

    it('renders proper colors', () => {
      expect(findHighlightedLineCode().exists()).toBe(true);
      expect(findHighlightedLineCode().at(2).text()).toBe('console.log("test")');
    });
  });
});
