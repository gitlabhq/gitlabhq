import createFlash from '~/flash';
import { __ } from '~/locale';
import { getBinary } from './services/image_service';

const imageRepository = () => {
  const images = new Map();
  const flash = (message) =>
    createFlash({
      message,
    });

  const add = (file, url) => {
    getBinary(file)
      .then((content) => images.set(url, content))
      .catch(() => flash(__('Something went wrong while inserting your image. Please try again.')));
  };

  const get = (path) => images.get(path);

  const getAll = () => images;

  return { add, get, getAll };
};

export default imageRepository;
