import Cookies from 'js-cookie';
import initBroadcastNotifications from '~/broadcast_notification';

describe('broadcast message on dismiss', () => {
  const dismiss = () => {
    const button = document.querySelector('.js-dismiss-current-broadcast-notification');
    button.click();
  };
  const endsAt = '2020-01-01T00:00:00Z';

  beforeEach(() => {
    setFixtures(`
    <div class="js-broadcast-notification-1">
      <button class="js-dismiss-current-broadcast-notification" data-id="1" data-expire-date="${endsAt}"></button>
    </div>
    `);

    initBroadcastNotifications();
  });

  it('removes broadcast message', () => {
    dismiss();

    expect(document.querySelector('.js-broadcast-notification-1')).toBeNull();
  });

  it('calls Cookies.set', () => {
    jest.spyOn(Cookies, 'set');
    dismiss();

    expect(Cookies.set).toHaveBeenCalledWith('hide_broadcast_message_1', true, {
      expires: new Date(endsAt),
    });
  });
});
