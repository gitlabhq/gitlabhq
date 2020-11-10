import { VALID_IMAGE_FILE_MIMETYPE } from './constants';

export const isValidImage = ({ type }) =>
  (type.match(VALID_IMAGE_FILE_MIMETYPE.regex) || []).length > 0;
