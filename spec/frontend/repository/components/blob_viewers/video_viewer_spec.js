import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VideoViewer from '~/repository/components/blob_viewers/video_viewer.vue';

describe('Video Viewer', () => {
  let wrapper;

  const propsData = { url: 'some/video.mp4' };

  const createComponent = () => {
    wrapper = shallowMountExtended(VideoViewer, { propsData });
  };

  const findVideo = () => wrapper.findByTestId('video');

  it('renders a Video element', () => {
    createComponent();

    expect(findVideo().exists()).toBe(true);
    expect(findVideo().attributes('src')).toBe(propsData.url);
    expect(findVideo().attributes('controls')).not.toBeUndefined();
  });
});
