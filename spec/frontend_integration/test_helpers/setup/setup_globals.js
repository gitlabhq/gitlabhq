import { initializeTestTimeout } from 'helpers/timeout';

initializeTestTimeout(process.env.CI ? 20000 : 7000);

beforeEach(() => {
  window.gon = {
    api_version: 'v4',
    relative_url_root: '',
  };
});
