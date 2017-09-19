export const getCoordinates = state =>
  imageDiffId => state.imageDiffs[imageDiffId] && state.imageDiffs[imageDiffId].coordinates;

export const getImages = state =>
  imageDiffId => state.imageDiffs[imageDiffId] && state.imageDiffs[imageDiffId].images;
