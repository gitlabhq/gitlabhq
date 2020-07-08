import { __ } from '~/locale';
import Flash from '~/flash';
import { getBinary } from './services/image_service';

const imageRepository = () => {
  const images = new Map();
  const flash = message => new Flash(message);

  const add = (file, url) => {
    getBinary(file)
      .then(content => images.set(url, content))
      .catch(() => flash(__('Something went wrong while inserting your image. Please try again.')));
  };

  const getAll = () => images;

  return { add, getAll };
};

export default imageRepository;
