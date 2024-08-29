import { nextTick } from 'vue';
import { GlSprintf, GlButton, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlobFooter from '~/search/results/components/blob_footer.vue';
import eventHub from '~/search/results/event_hub';
import { mockDataForBlobBody } from '../../mock_data';

describe('BlobFooter', () => {
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
        'Show less - Too many matches found. Showing 50 chunks out of 200 results. Open the file to view all.',
      );
    });
  });
});
