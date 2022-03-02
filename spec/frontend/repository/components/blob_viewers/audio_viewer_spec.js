import { shallowMount } from '@vue/test-utils';
import AudioViewer from '~/repository/components/blob_viewers/audio_viewer.vue';

describe('Audio Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    rawPath: 'some/audio.mid',
  };

  const createComponent = () => {
    wrapper = shallowMount(AudioViewer, { propsData: { blob: DEFAULT_BLOB_DATA } });
  };

  const findContent = () => wrapper.find('[data-testid="audio"]');

  it('renders an audio source component', () => {
    createComponent();

    expect(findContent().exists()).toBe(true);
    expect(findContent().attributes('src')).toBe(DEFAULT_BLOB_DATA.rawPath);
  });
});
