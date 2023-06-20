import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoJsonViewer from '~/repository/components/blob_viewers/geo_json/geo_json_viewer.vue';
import { initLeafletMap } from '~/repository/components/blob_viewers/geo_json/utils';
import { RENDER_ERROR_MSG } from '~/repository/components/blob_viewers/geo_json/constants';
import { createAlert } from '~/alert';

jest.mock('~/repository/components/blob_viewers/geo_json/utils');
jest.mock('~/alert');

describe('GeoJson Viewer', () => {
  let wrapper;

  const GEO_JSON_MOCK_DATA = '{ "type": "FeatureCollection" }';

  const createComponent = (rawTextBlob = GEO_JSON_MOCK_DATA) => {
    wrapper = shallowMountExtended(GeoJsonViewer, {
      propsData: { blob: { rawTextBlob } },
    });
  };

  beforeEach(() => createComponent());

  const findMapWrapper = () => wrapper.findByTestId('map');

  it('calls a the initLeafletMap util', () => {
    const mapWrapper = findMapWrapper();

    expect(initLeafletMap).toHaveBeenCalledWith(mapWrapper.element, JSON.parse(GEO_JSON_MOCK_DATA));
    expect(mapWrapper.exists()).toBe(true);
  });

  it('displays an error if invalid json is provided', async () => {
    createComponent('invalid JSON');
    await nextTick();

    expect(createAlert).toHaveBeenCalledWith({ message: RENDER_ERROR_MSG });
    expect(findMapWrapper().exists()).toBe(false);
  });
});
