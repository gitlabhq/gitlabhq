import { MODULE_SAST, MODULE_SECRET_DETECTION } from './constants';

export default () => ({
  reportTypes: [MODULE_SAST, MODULE_SECRET_DETECTION],
});
