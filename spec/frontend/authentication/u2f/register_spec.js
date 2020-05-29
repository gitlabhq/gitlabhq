import $ from 'jquery';
import U2FRegister from '~/authentication/u2f/register';
import 'vendor/u2f';
import MockU2FDevice from './mock_u2f_device';

describe('U2FRegister', () => {
  let u2fDevice;
  let container;
  let component;

  preloadFixtures('u2f/register.html');

  beforeEach(done => {
    loadFixtures('u2f/register.html');
    u2fDevice = new MockU2FDevice();
    container = $('#js-register-u2f');
    component = new U2FRegister(container, $('#js-register-u2f-templates'), {}, 'token');
    component
      .start()
      .then(done)
      .catch(done.fail);
  });

  it('allows registering a U2F device', () => {
    const setupButton = container.find('#js-setup-u2f-device');

    expect(setupButton.text()).toBe('Set up new U2F device');
    setupButton.trigger('click');
    const inProgressMessage = container.children('p');

    expect(inProgressMessage.text()).toContain('Trying to communicate with your device');
    u2fDevice.respondToRegisterRequest({
      deviceData: 'this is data from the device',
    });
    const registeredMessage = container.find('p');
    const deviceResponse = container.find('#js-device-response');

    expect(registeredMessage.text()).toContain('Your device was successfully set up!');
    expect(deviceResponse.val()).toBe('{"deviceData":"this is data from the device"}');
  });

  describe('errors', () => {
    it("doesn't allow the same device to be registered twice (for the same user", () => {
      const setupButton = container.find('#js-setup-u2f-device');
      setupButton.trigger('click');
      u2fDevice.respondToRegisterRequest({
        errorCode: 4,
      });
      const errorMessage = container.find('p');

      expect(errorMessage.text()).toContain('already been registered with us');
    });

    it('displays an error message for other errors', () => {
      const setupButton = container.find('#js-setup-u2f-device');
      setupButton.trigger('click');
      u2fDevice.respondToRegisterRequest({
        errorCode: 'error!',
      });
      const errorMessage = container.find('p');

      expect(errorMessage.text()).toContain('There was a problem communicating with your device');
    });

    it('allows retrying registration after an error', () => {
      let setupButton = container.find('#js-setup-u2f-device');
      setupButton.trigger('click');
      u2fDevice.respondToRegisterRequest({
        errorCode: 'error!',
      });
      const retryButton = container.find('#U2FTryAgain');
      retryButton.trigger('click');
      setupButton = container.find('#js-setup-u2f-device');
      setupButton.trigger('click');
      u2fDevice.respondToRegisterRequest({
        deviceData: 'this is data from the device',
      });
      const registeredMessage = container.find('p');

      expect(registeredMessage.text()).toContain('Your device was successfully set up!');
    });
  });
});
