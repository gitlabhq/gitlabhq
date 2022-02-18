import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VideoViewer from '~/repository/components/blob_viewers/video_viewer.vue';

describe('Video Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = { rawPath: 'some/video.mp4' };

  const createComponent = () => {
    wrapper = shallowMountExtended(VideoViewer, { propsData: { blob: { ...DEFAULT_BLOB_DATA } } });
  };

  const findVideo = () => wrapper.findByTestId('video');

  it('renders a Video element', () => {
    createComponent();

    expect(findVideo().exists()).toBe(true);
    expect(findVideo().attributes('src')).toBe(DEFAULT_BLOB_DATA.rawPath);
    expect(findVideo().attributes('controls')).not.toBeUndefined();
  });
});
