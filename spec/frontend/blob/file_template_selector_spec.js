import FileTemplateSelector from '~/blob/file_template_selector';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('FileTemplateSelector', () => {
  let subject;

  const dropdown = '.dropdown';
  const wrapper = '.wrapper';

  const createSubject = () => {
    subject = new FileTemplateSelector({});
    subject.config = {
      dropdown,
      wrapper,
    };
    subject.initDropdown = jest.fn();
  };

  afterEach(() => {
    subject = null;
    resetHTMLFixture();
  });

  describe('show method', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <div class="wrapper hidden">
          <div class="dropdown"></div>
        </div>
      `);
      createSubject();
    });

    it('calls init on first call', () => {
      jest.spyOn(subject, 'init');
      subject.show();

      expect(subject.init).toHaveBeenCalledTimes(1);
    });

    it('does not call init on subsequent calls', () => {
      jest.spyOn(subject, 'init');
      subject.show();

      expect(subject.init).toHaveBeenCalledTimes(1);
    });

    it('removes hidden class from wrapper', () => {
      subject.init();
      expect(subject.wrapper.classList.contains('hidden')).toBe(true);

      subject.show();
      expect(subject.wrapper.classList.contains('hidden')).toBe(false);
    });

    it('sets the focus on the dropdown', () => {
      subject.show();
      jest.spyOn(subject.dropdown, 'focus');
      jest.runAllTimers();

      expect(subject.dropdown.focus).toHaveBeenCalled();
    });
  });
});
