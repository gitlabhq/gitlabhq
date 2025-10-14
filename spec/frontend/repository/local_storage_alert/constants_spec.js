import { LOCAL_STORAGE_ALERT_KEY } from '~/repository/local_storage_alert/constants';

describe('LOCAL_STORAGE_ALERT_KEY', () => {
  it('exports the correct localStorage key', () => {
    expect(LOCAL_STORAGE_ALERT_KEY).toBe('repository_alert');
  });
});
