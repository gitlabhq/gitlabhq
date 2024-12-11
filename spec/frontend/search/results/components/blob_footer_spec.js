import { nextTick } from 'vue';
import { GlSprintf, GlButton, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlobFooter from '~/search/results/components/blob_footer.vue';
import eventHub from '~/search/results/event_hub';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { EVENT_CLICK_BLOB_RESULTS_SHOW_MORE_LESS } from '~/search/results/tracking';
import { mockDataForBlobBody } from '../../mock_data';

describe('BlobFooter', () => {
  const { bindInternalEventDocument } = useMockInternalEventsTracking();
  let wrapper;
  let spy;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(BlobFooter, {
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
        GlLink,
      },
    });
  };

  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe('component basics', () => {
    beforeEach(() => {
      createComponent({
        file: mockDataForBlobBody,
        position: 1,
      });
      spy = jest.spyOn(eventHub, '$emit');
    });

    it(`renders default closed state`, () => {
      expect(findGlButton().exists()).toBe(true);
      expect(wrapper.text()).toContain('Show 1 more matches');
    });

    it(`renders default open state`, async () => {
      findGlButton().vm.$emit('click');
      await nextTick();
      expect(spy).toHaveBeenCalledWith('showMore', {
        id: 'Testjs/Test:file/test.js',
        state: true,
      });
      expect(wrapper.text()).toContain('Show less');
    });
  });

  describe('component with too many results', () => {
    beforeEach(() => {
      createComponent({
        file: {
          ...mockDataForBlobBody,
          chunks: [
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
            ...mockDataForBlobBody.chunks,
          ],
          matchCountTotal: 200,
        },
        position: 1,
      });
    });

    it(`renders closed state`, () => {
      expect(findGlButton().exists()).toBe(true);
      expect(wrapper.text()).toContain('Show 97 more matches');
    });

    it(`renders open state`, async () => {
      findGlButton().vm.$emit('click');
      await nextTick();
      expect(findGlLink().exists()).toBe(true);
      expect(wrapper.text()).toContain(
        `Show less - Too many matches found. Showing 5 chunks out of 200 results. Open the file to view all.`,
      );
    });

    it(`tracks show more or less click`, () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      findGlButton().vm.$emit('click', { value: 1 });

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_CLICK_BLOB_RESULTS_SHOW_MORE_LESS,
        {
          label: '1',
          property: 'open',
        },
        undefined,
      );

      findGlButton().vm.$emit('click', { value: 1 });

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_CLICK_BLOB_RESULTS_SHOW_MORE_LESS,
        {
          label: '1',
          property: 'close',
        },
        undefined,
      );
    });
  });
});
