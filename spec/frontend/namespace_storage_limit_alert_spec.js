import Cookies from 'js-cookie';
import initNamespaceStorageLimitAlert from '~/namespace_storage_limit_alert';

describe('broadcast message on dismiss', () => {
  const dismiss = () => {
    const button = document.querySelector('.js-namespace-storage-alert-dismiss');
    button.click();
  };

  beforeEach(() => {
    setFixtures(`
    <div class="js-namespace-storage-alert">
      <button class="js-namespace-storage-alert-dismiss" data-id="1" data-level="info"></button>
    </div>
    `);

    initNamespaceStorageLimitAlert();
  });

  it('removes alert', () => {
    expect(document.querySelector('.js-namespace-storage-alert')).toBeTruthy();

    dismiss();

    expect(document.querySelector('.js-namespace-storage-alert')).toBeNull();
  });

  it('calls Cookies.set', () => {
    jest.spyOn(Cookies, 'set');
    dismiss();

    expect(Cookies.set).toHaveBeenCalledWith('hide_storage_limit_alert_1_info', true, {
      expires: 365,
    });
  });
});
