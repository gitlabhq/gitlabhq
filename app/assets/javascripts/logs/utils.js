import dateFormat from 'dateformat';
import { dateFormatMask } from './constants';

export const formatDate = (timestamp) => dateFormat(timestamp, dateFormatMask);
