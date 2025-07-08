import { setupIdeContainer } from '~/ide/lib/gitlab_web_ide/setup_ide_container';

describe('~/ide/lib/gitlab_web_ide/setup_ide_container', () => {
  let baseEl;

  beforeEach(() => {
    baseEl = document.createElement('div');
    baseEl.id = 'test-ide-container';
    document.body.appendChild(baseEl);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('setupIdeContainer', () => {
    it('creates a new div element with the same id as the base element', () => {
      const result = setupIdeContainer(baseEl);

      expect(result.element.tagName).toBe('DIV');
      expect(result.element.id).toBe('test-ide-container');
    });

    it('adds the correct CSS classes to the new element', () => {
      const result = setupIdeContainer(baseEl);

      expect(Array.from(result.element.classList)).toEqual([
        'gl-hidden',
        'gl-justify-center',
        'gl-items-center',
        'gl-relative',
        'gl-h-full',
      ]);
    });

    it('inserts the new element after the base element', () => {
      const result = setupIdeContainer(baseEl);

      expect(result.element.previousElementSibling).toBe(baseEl);
    });

    it('returns an object with element', () => {
      const result = setupIdeContainer(baseEl);

      expect(result).toHaveProperty('element');
    });

    describe('show method', () => {
      it('adds gl-flex class and removes gl-hidden class from element', () => {
        const result = setupIdeContainer(baseEl);

        result.show();

        expect(result.element.classList.contains('gl-flex')).toBe(true);
        expect(result.element.classList.contains('gl-hidden')).toBe(false);
      });

      it('removes the base element from the DOM', () => {
        const result = setupIdeContainer(baseEl);

        expect(document.body.contains(baseEl)).toBe(true);

        result.show();

        expect(document.body.contains(baseEl)).toBe(false);
      });
    });
  });
});
