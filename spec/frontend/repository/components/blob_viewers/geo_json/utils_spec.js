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

  describe('popupContent', () => {
    const renderPopup = (properties) => {
      const el = document.createElement('div');
      el.innerHTML = utils.popupContent(properties);
      return el;
    };

    const findRows = (el) =>
      [...el.firstElementChild.children].map((row) => ({
        label: row.querySelector('strong').textContent,
        value: row.querySelector('span').textContent,
      }));

    it('renders one row per property, in order', () => {
      const el = renderPopup({ name: 'Park', area: 'North' });

      expect(findRows(el)).toEqual([
        { label: 'name:', value: 'Park' },
        { label: 'area:', value: 'North' },
      ]);
    });

    it('renders an empty popup when there are no properties', () => {
      expect(findRows(renderPopup({}))).toEqual([]);
    });

    it('escapes HTML in labels and values', () => {
      const el = renderPopup({
        '<img src=x onerror=alert(1)>': '<script>alert(2)</script>',
        quotes: `"double" & 'single'`,
      });

      expect(el.querySelector('img')).toBeNull();
      expect(el.querySelector('script')).toBeNull();
      expect(findRows(el)).toEqual([
        { label: '<img src=x onerror=alert(1)>:', value: '<script>alert(2)</script>' },
        { label: 'quotes:', value: `"double" & 'single'` },
      ]);
    });

    it('renders non-string values as text', () => {
      const el = renderPopup({
        empty: null,
        missing: undefined,
        zero: 0,
        flag: false,
        list: [1, 2],
        nested: { a: 1 },
      });

      expect(findRows(el)).toEqual([
        { label: 'empty:', value: '' },
        { label: 'missing:', value: '' },
        { label: 'zero:', value: '0' },
        { label: 'flag:', value: 'false' },
        { label: 'list:', value: '1,2' },
        { label: 'nested:', value: '[object Object]' },
      ]);
    });

    it('renders a numeric "length" property as a regular property', () => {
      const el = renderPopup({ name: 'Main Street', length: 2 });

      expect(findRows(el)).toEqual([
        { label: 'name:', value: 'Main Street' },
        { label: 'length:', value: '2' },
      ]);
    });
  });
});
