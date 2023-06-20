import { map, tileLayer, geoJson, featureGroup, Icon } from 'leaflet';
import * as utils from '~/repository/components/blob_viewers/geo_json/utils';
import {
  OPEN_STREET_TILE_URL,
  MAP_ATTRIBUTION,
  OPEN_STREET_COPYRIGHT_LINK,
  ICON_CONFIG,
} from '~/repository/components/blob_viewers/geo_json/constants';

jest.mock('leaflet', () => ({
  featureGroup: () => ({ getBounds: jest.fn() }),
  Icon: { Default: { mergeOptions: jest.fn() } },
  tileLayer: jest.fn(),
  map: jest.fn().mockReturnValue({ fitBounds: jest.fn() }),
  geoJson: jest.fn().mockReturnValue({ addTo: jest.fn() }),
}));

describe('GeoJson utilities', () => {
  const mockWrapper = document.createElement('div');
  const mockData = { test: 'data' };

  describe('initLeafletMap', () => {
    describe('valid params', () => {
      beforeEach(() => utils.initLeafletMap(mockWrapper, mockData));

      it('sets the correct icon', () => {
        expect(Icon.Default.mergeOptions).toHaveBeenCalledWith(ICON_CONFIG);
      });

      it('inits the leaflet map', () => {
        const attribution = `${MAP_ATTRIBUTION} ${OPEN_STREET_COPYRIGHT_LINK}`;

        expect(tileLayer).toHaveBeenCalledWith(OPEN_STREET_TILE_URL, { attribution });
        expect(map).toHaveBeenCalledWith(mockWrapper, { layers: [] });
      });

      it('adds geojson data to the leaflet map', () => {
        expect(geoJson().addTo).toHaveBeenCalledWith(map());
      });

      it('fits the map to the correct bounds', () => {
        expect(map().fitBounds).toHaveBeenCalledWith(featureGroup().getBounds());
      });

      it('generates popup content containing the metaData', () => {
        const popupContent = utils.popupContent(mockData);

        expect(popupContent).toContain(Object.keys(mockData)[0]);
        expect(popupContent).toContain(mockData.test);
      });
    });

    describe('invalid params', () => {
      it.each([
        [null, null],
        [null, mockData],
        [mockWrapper, null],
      ])('does nothing (returns early) if any of the params are not provided', (wrapper, data) => {
        utils.initLeafletMap(wrapper, data);
        expect(Icon.Default.mergeOptions).not.toHaveBeenCalled();
        expect(tileLayer).not.toHaveBeenCalled();
        expect(map).not.toHaveBeenCalled();
        expect(geoJson().addTo).not.toHaveBeenCalled();
        expect(map().fitBounds).not.toHaveBeenCalled();
      });
    });
  });
});
