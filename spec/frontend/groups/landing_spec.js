import Cookies from '~/lib/utils/cookies';
import Landing from '~/groups/landing';

describe('Landing', () => {
  const test = {};

  describe('class constructor', () => {
    beforeEach(() => {
      test.landingElement = {};
      test.dismissButton = {};
      test.cookieName = 'cookie_name';

      test.landing = new Landing(test.landingElement, test.dismissButton, test.cookieName);
    });

    it('should set .landing', () => {
      expect(test.landing.landingElement).toBe(test.landingElement);
    });

    it('should set .cookieName', () => {
      expect(test.landing.cookieName).toBe(test.cookieName);
    });

    it('should set .dismissButton', () => {
      expect(test.landing.dismissButton).toBe(test.dismissButton);
    });

    it('should set .eventWrapper', () => {
      expect(test.landing.eventWrapper).toEqual({});
    });
  });

  describe('toggle', () => {
    beforeEach(() => {
      test.isDismissed = false;
      test.landingElement = {
        classList: {
          toggle: jest.fn(),
        },
      };
      test.landing = {
        isDismissed: () => {},
        addEvents: () => {},
        landingElement: test.landingElement,
      };

      jest.spyOn(test.landing, 'isDismissed').mockReturnValue(test.isDismissed);
      jest.spyOn(test.landing, 'addEvents').mockImplementation(() => {});

      Landing.prototype.toggle.call(test.landing);
    });

    it('should call .isDismissed', () => {
      expect(test.landing.isDismissed).toHaveBeenCalled();
    });

    it('should call .classList.toggle', () => {
      expect(test.landingElement.classList.toggle).toHaveBeenCalledWith('hidden', test.isDismissed);
    });

    it('should call .addEvents', () => {
      expect(test.landing.addEvents).toHaveBeenCalled();
    });

    describe('if isDismissed is true', () => {
      beforeEach(() => {
        test.isDismissed = true;
        test.landingElement = {
          classList: {
            toggle: jest.fn(),
          },
        };
        test.landing = {
          isDismissed: () => {},
          addEvents: () => {},
          landingElement: test.landingElement,
        };

        jest.spyOn(test.landing, 'isDismissed').mockReturnValue(test.isDismissed);
        jest.spyOn(test.landing, 'addEvents').mockImplementation(() => {});

        test.landing.isDismissed.mockClear();

        Landing.prototype.toggle.call(test.landing);
      });

      it('should not call .addEvents', () => {
        expect(test.landing.addEvents).not.toHaveBeenCalled();
      });
    });
  });

  describe('addEvents', () => {
    beforeEach(() => {
      test.dismissButton = {
        addEventListener: jest.fn(),
      };
      test.eventWrapper = {};
      test.landing = {
        eventWrapper: test.eventWrapper,
        dismissButton: test.dismissButton,
        dismissLanding: () => {},
      };

      Landing.prototype.addEvents.call(test.landing);
    });

    it('should set .eventWrapper.dismissLanding', () => {
      expect(test.eventWrapper.dismissLanding).toEqual(expect.any(Function));
    });

    it('should call .addEventListener', () => {
      expect(test.dismissButton.addEventListener).toHaveBeenCalledWith(
        'click',
        test.eventWrapper.dismissLanding,
      );
    });
  });

  describe('removeEvents', () => {
    beforeEach(() => {
      test.dismissButton = {
        removeEventListener: jest.fn(),
      };
      test.eventWrapper = { dismissLanding: () => {} };
      test.landing = {
        eventWrapper: test.eventWrapper,
        dismissButton: test.dismissButton,
      };

      Landing.prototype.removeEvents.call(test.landing);
    });

    it('should call .removeEventListener', () => {
      expect(test.dismissButton.removeEventListener).toHaveBeenCalledWith(
        'click',
        test.eventWrapper.dismissLanding,
      );
    });
  });

  describe('dismissLanding', () => {
    beforeEach(() => {
      test.landingElement = {
        classList: {
          add: jest.fn(),
        },
      };
      test.cookieName = 'cookie_name';
      test.landing = { landingElement: test.landingElement, cookieName: test.cookieName };

      jest.spyOn(Cookies, 'set').mockImplementation(() => {});

      Landing.prototype.dismissLanding.call(test.landing);
    });

    it('should call .classList.add', () => {
      expect(test.landingElement.classList.add).toHaveBeenCalledWith('hidden');
    });

    it('should call Cookies.set', () => {
      expect(Cookies.set).toHaveBeenCalledWith(test.cookieName, 'true', {
        expires: 365,
        secure: false,
      });
    });
  });

  describe('isDismissed', () => {
    beforeEach(() => {
      test.cookieName = 'cookie_name';
      test.landing = { cookieName: test.cookieName };

      jest.spyOn(Cookies, 'get').mockReturnValue('true');

      test.isDismissed = Landing.prototype.isDismissed.call(test.landing);
    });

    it('should call Cookies.get', () => {
      expect(Cookies.get).toHaveBeenCalledWith(test.cookieName);
    });

    it('should return a boolean', () => {
      expect(typeof test.isDismissed).toEqual('boolean');
    });
  });
});
