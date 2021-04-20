import $ from 'jquery';
import FileTemplateSelector from '~/blob/file_template_selector';

describe('FileTemplateSelector', () => {
  let subject;
  let dropdown;
  let wrapper;

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
  });

  describe('show method', () => {
    beforeEach(() => {
      dropdown = document.createElement('div');
      wrapper = document.createElement('div');
      wrapper.classList.add('hidden');
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
      subject.show();

      expect(subject.init).toHaveBeenCalledTimes(1);
    });

    it('removes hidden class from $wrapper', () => {
      expect($(wrapper).hasClass('hidden')).toBe(true);

      subject.show();

      expect($(wrapper).hasClass('hidden')).toBe(false);
    });

    it('sets the focus on the dropdown', async () => {
      subject.show();
      jest.spyOn(subject.$dropdown, 'focus');
      jest.runAllTimers();

      expect(subject.$dropdown.focus).toHaveBeenCalled();
    });
  });
});
