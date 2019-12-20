import $ from 'jquery';
import { togglePopover, mouseleave, mouseenter } from '~/shared/popover';

describe('popover', () => {
  describe('togglePopover', () => {
    describe('togglePopover(true)', () => {
      it('returns true when popover is shown', () => {
        const context = {
          hasClass: () => false,
          popover: () => {},
          toggleClass: () => {},
        };

        expect(togglePopover.call(context, true)).toEqual(true);
      });

      it('returns false when popover is already shown', () => {
        const context = {
          hasClass: () => true,
        };

        expect(togglePopover.call(context, true)).toEqual(false);
      });

      it('shows popover', done => {
        const context = {
          hasClass: () => false,
          popover: () => {},
          toggleClass: () => {},
        };

        jest.spyOn(context, 'popover').mockImplementation(method => {
          expect(method).toEqual('show');
          done();
        });

        togglePopover.call(context, true);
      });

      it('adds disable-animation and js-popover-show class', done => {
        const context = {
          hasClass: () => false,
          popover: () => {},
          toggleClass: () => {},
        };

        jest.spyOn(context, 'toggleClass').mockImplementation((classNames, show) => {
          expect(classNames).toEqual('disable-animation js-popover-show');
          expect(show).toEqual(true);
          done();
        });

        togglePopover.call(context, true);
      });
    });

    describe('togglePopover(false)', () => {
      it('returns true when popover is hidden', () => {
        const context = {
          hasClass: () => true,
          popover: () => {},
          toggleClass: () => {},
        };

        expect(togglePopover.call(context, false)).toEqual(true);
      });

      it('returns false when popover is already hidden', () => {
        const context = {
          hasClass: () => false,
        };

        expect(togglePopover.call(context, false)).toEqual(false);
      });

      it('hides popover', done => {
        const context = {
          hasClass: () => true,
          popover: () => {},
          toggleClass: () => {},
        };

        jest.spyOn(context, 'popover').mockImplementation(method => {
          expect(method).toEqual('hide');
          done();
        });

        togglePopover.call(context, false);
      });

      it('removes disable-animation and js-popover-show class', done => {
        const context = {
          hasClass: () => true,
          popover: () => {},
          toggleClass: () => {},
        };

        jest.spyOn(context, 'toggleClass').mockImplementation((classNames, show) => {
          expect(classNames).toEqual('disable-animation js-popover-show');
          expect(show).toEqual(false);
          done();
        });

        togglePopover.call(context, false);
      });
    });
  });

  describe('mouseleave', () => {
    it('calls hide popover if .popover:hover is false', () => {
      const fakeJquery = {
        length: 0,
      };

      jest
        .spyOn($.fn, 'init')
        .mockImplementation(selector => (selector === '.popover:hover' ? fakeJquery : $.fn));
      jest.spyOn(togglePopover, 'call').mockImplementation(() => {});
      mouseleave();

      expect(togglePopover.call).toHaveBeenCalledWith(expect.any(Object), false);
    });

    it('does not call hide popover if .popover:hover is true', () => {
      const fakeJquery = {
        length: 1,
      };

      jest
        .spyOn($.fn, 'init')
        .mockImplementation(selector => (selector === '.popover:hover' ? fakeJquery : $.fn));
      jest.spyOn(togglePopover, 'call').mockImplementation(() => {});
      mouseleave();

      expect(togglePopover.call).not.toHaveBeenCalledWith(false);
    });
  });

  describe('mouseenter', () => {
    const context = {};

    it('shows popover', () => {
      jest.spyOn(togglePopover, 'call').mockReturnValue(false);
      mouseenter.call(context);

      expect(togglePopover.call).toHaveBeenCalledWith(expect.any(Object), true);
    });

    it('registers mouseleave event if popover is showed', done => {
      jest.spyOn(togglePopover, 'call').mockReturnValue(true);
      jest.spyOn($.fn, 'on').mockImplementation(eventName => {
        expect(eventName).toEqual('mouseleave');
        done();
      });
      mouseenter.call(context);
    });

    it('does not register mouseleave event if popover is not showed', () => {
      jest.spyOn(togglePopover, 'call').mockReturnValue(false);
      const spy = jest.spyOn($.fn, 'on').mockImplementation(() => {});
      mouseenter.call(context);

      expect(spy).not.toHaveBeenCalled();
    });
  });
});
