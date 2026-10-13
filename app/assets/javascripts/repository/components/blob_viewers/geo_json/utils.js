import { map, tileLayer, geoJson, featureGroup, Icon } from 'leaflet';
import { escape } from 'lodash-es';
import {
  OPEN_STREET_TILE_URL,
  MAP_ATTRIBUTION,
  OPEN_STREET_COPYRIGHT_LINK,
  ICON_CONFIG,
} from './constants';

const generateOpenStreetMapTiles = () => {
  const attribution = `${MAP_ATTRIBUTION} ${OPEN_STREET_COPYRIGHT_LINK}`;
  return tileLayer(OPEN_STREET_TILE_URL, { attribution });
};

export const popupContent = (popupProperties) => {
  const rows = Object.entries(popupProperties)
    .map(
      ([label, value]) =>
        `<div><strong>${escape(label)}:</strong> <span>${escape(value)}</span></div>`,
    )
    .join('');

  return `<div class="gl-pt-4">${rows}</div>`;
};

const loadGeoJsonGroupAndBounds = (geoJsonData) => {
  const layers = [];
  const geoJsonGroup = geoJson(geoJsonData, {
    onEachFeature: (feature, layer) => {
      layers.push(layer);
      if (feature.properties) {
        layer.bindPopup(popupContent(feature.properties));
      }
    },
  });

  return { geoJsonGroup, bounds: featureGroup(layers).getBounds() };
};

export const initLeafletMap = (el, geoJsonData) => {
  if (!el || !geoJsonData) return;

  import('leaflet/dist/leaflet.css');
  Icon.Default.mergeOptions(ICON_CONFIG);
  const leafletMap = map(el, { layers: [generateOpenStreetMapTiles()] });
  const { bounds, geoJsonGroup } = loadGeoJsonGroupAndBounds(geoJsonData);

  geoJsonGroup.addTo(leafletMap);
  leafletMap.fitBounds(bounds);
};
