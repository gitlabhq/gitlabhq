import axios from './axios_utils';
import { setFaviconOverlay, resetFavicon } from './favicon';

export const setCiStatusFavicon = (pageUrl) =>
  axios
    .get(pageUrl)
    .then(({ data }) => {
      if (data && data.favicon) {
        return setFaviconOverlay(data.favicon);
      }
      return resetFavicon();
    })
    .catch((error) => {
      resetFavicon();
      throw error;
    });
