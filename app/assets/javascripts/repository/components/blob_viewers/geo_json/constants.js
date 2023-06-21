import iconUrl from 'leaflet/dist/images/marker-icon.png';
import iconRetinaUrl from 'leaflet/dist/images/marker-icon-2x.png';
import shadowUrl from 'leaflet/dist/images/marker-shadow.png';
import { __ } from '~/locale';

export const RENDER_ERROR_MSG = __(
  'The map can not be displayed because there was an error loading the GeoJSON file.',
);

export const OPEN_STREET_TILE_URL = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
export const ICON_CONFIG = { iconUrl, iconRetinaUrl, shadowUrl };
export const MAP_ATTRIBUTION = __('Map data from');
export const OPEN_STREET_COPYRIGHT_LINK =
  '<a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener noreferrer">OpenStreetMap</a>';

export const POPUP_CONTENT_TEMPLATE = `
<div class="gl-pt-4">
  <% eachFunction(popupProperties, function(value, label) { %>
    <div>
      <strong><%- label %>:</strong> <span><%- value %></span>
    </div>
  <% }); %>
</div>
`;
