import createFlash, {
  createFlashEl,
  createAction,
  hideFlash,
  removeFlashClickListener,
} from '~/flash';

describe('Flash', () => {
  describe('createFlashEl', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
    });

    afterEach(() => {
      el.innerHTML = '';
    });

    it('creates flash element with type', () => {
      el.innerHTML = createFlashEl('testing', 'alert');

      expect(el.querySelector('.flash-alert')).not.toBeNull();
    });

    it('escapes text', () => {
      el.innerHTML = createFlashEl('<script>alert("a");</script>', 'alert');

      expect(el.querySelector('.flash-text').textContent.trim()).toBe(
        '<script>alert("a");</script>',
      );
    });
  });

  describe('hideFlash', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
      el.className = 'js-testing';
    });

    it('sets transition style', () => {
      hideFlash(el);

      expect(el.style.transition).toBe('opacity 0.15s');
    });

    it('sets opacity style', () => {
      hideFlash(el);

      expect(el.style.opacity).toBe('0');
    });

    it('does not set styles when fadeTransition is false', () => {
      hideFlash(el, false);

      expect(el.style.opacity).toBe('');
      expect(el.style.transition).toBeFalsy();
    });

    it('removes element after transitionend', () => {
      document.body.appendChild(el);

      hideFlash(el);
      el.dispatchEvent(new Event('transitionend'));

      expect(document.querySelector('.js-testing')).toBeNull();
    });

    it('calls event listener callback once', () => {
      jest.spyOn(el, 'remove');
      document.body.appendChild(el);

      hideFlash(el);

      el.dispatchEvent(new Event('transitionend'));
      el.dispatchEvent(new Event('transitionend'));

      expect(el.remove.mock.calls.length).toBe(1);
    });
  });

  describe('createAction', () => {
    let el;

    beforeEach(() => {
      el = document.createElement('div');
    });

    it('creates link with href', () => {
      el.innerHTML = createAction({
        href: 'testing',
        title: 'test',
      });

      expect(el.querySelector('.flash-action').href).toContain('testing');
    });

    it('uses hash as href when no href is present', () => {
      el.innerHTML = createAction({
        title: 'test',
      });

      expect(el.querySelector('.flash-action').href).toContain('#');
    });

    it('adds role when no href is present', () => {
      el.innerHTML = createAction({
        title: 'test',
      });

      expect(el.querySelector('.flash-action').getAttribute('role')).toBe('button');
    });

    it('escapes the title text', () => {
      el.innerHTML = createAction({
        title: '<script>alert("a")</script>',
      });

      expect(el.querySelector('.flash-action').textContent.trim()).toBe(
        '<script>alert("a")</script>',
      );
    });
  });

  describe('createFlash', () => {
    const message = 'test';
    const type = 'alert';
    const parent = document;
    const fadeTransition = false;
    const addBodyClass = true;
    const defaultParams = {
      message,
      type,
      parent,
      actionConfig: null,
      fadeTransition,
      addBodyClass,
    };

    describe('no flash-container', () => {
      it('does not add to the DOM', () => {
        const flashEl = createFlash({ message });

        expect(flashEl).toBeNull();

        expect(document.querySelector('.flash-alert')).toBeNull();
      });
    });

    describe('with flash-container', () => {
      beforeEach(() => {
        setFixtures(
          '<div class="content-wrapper js-content-wrapper"><div class="flash-container"></div></div>',
        );
      });

      afterEach(() => {
        document.querySelector('.js-content-wrapper').remove();
      });

      it('adds flash element into container', () => {
        createFlash({ ...defaultParams });

        expect(document.querySelector('.flash-alert')).not.toBeNull();

        expect(document.body.className).toContain('flash-shown');
      });

      it('adds flash into specified parent', () => {
        createFlash({ ...defaultParams, parent: document.querySelector('.content-wrapper') });

        expect(document.querySelector('.content-wrapper .flash-alert')).not.toBeNull();
        expect(document.querySelector('.content-wrapper').innerText.trim()).toEqual(message);
      });

      it('adds container classes when inside content-wrapper', () => {
        createFlash(defaultParams);

        expect(document.querySelector('.flash-text').className).toBe('flash-text');
        expect(document.querySelector('.content-wrapper').innerText.trim()).toEqual(message);
      });

      it('does not add container when outside of content-wrapper', () => {
        document.querySelector('.content-wrapper').className = 'js-content-wrapper';
        createFlash(defaultParams);

        expect(document.querySelector('.flash-text').className.trim()).toContain('flash-text');
      });

      it('removes element after clicking', () => {
        createFlash({ ...defaultParams });

        document.querySelector('.flash-alert .js-close-icon').click();

        expect(document.querySelector('.flash-alert')).toBeNull();

        expect(document.body.className).not.toContain('flash-shown');
      });

      describe('with actionConfig', () => {
        it('adds action link', () => {
          createFlash({
            ...defaultParams,
            actionConfig: {
              title: 'test',
            },
          });

          expect(document.querySelector('.flash-action')).not.toBeNull();
        });

        it('calls actionConfig clickHandler on click', () => {
          const actionConfig = {
            title: 'test',
            clickHandler: jest.fn(),
          };

          createFlash({ ...defaultParams, actionConfig });

          document.querySelector('.flash-action').click();

          expect(actionConfig.clickHandler).toHaveBeenCalled();
        });
      });

      describe('additional behavior', () => {
        describe('close', () => {
          it('clicks the close icon', () => {
            const flash = createFlash({ ...defaultParams });
            const close = document.querySelector('.flash-alert .js-close-icon');

            jest.spyOn(close, 'click');
            flash.close();

            expect(close.click.mock.calls.length).toBe(1);
          });
        });
      });
    });
  });

  describe('removeFlashClickListener', () => {
    let el;

    describe('with close icon', () => {
      beforeEach(() => {
        el = document.createElement('div');
        el.innerHTML = `
          <div class="flash-container">
            <div class="flash">
              <div class="close-icon js-close-icon"></div>
            </div>
          </div>
        `;
      });

      it('removes global flash on click', (done) => {
        removeFlashClickListener(el, false);

        el.querySelector('.js-close-icon').click();

        setImmediate(() => {
          expect(document.querySelector('.flash')).toBeNull();

          done();
        });
      });
    });

    describe('without close icon', () => {
      beforeEach(() => {
        el = document.createElement('div');
        el.innerHTML = `
          <div class="flash-container">
            <div class="flash">
            </div>
          </div>
        `;
      });

      it('does not throw', () => {
        expect(() => removeFlashClickListener(el, false)).not.toThrow();
      });
    });
  });
});
