import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlLink } from '@gitlab/ui';
import LineNumbers from '~/vue_shared/components/line_numbers.vue';

describe('Line Numbers component', () => {
  let wrapper;
  const lines = 10;

  const createComponent = () => {
    wrapper = shallowMount(LineNumbers, { propsData: { lines } });
  };

  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findLineNumbers = () => wrapper.findAllComponents(GlLink);
  const findFirstLineNumber = () => findLineNumbers().at(0);
  const findSecondLineNumber = () => findLineNumbers().at(1);

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  describe('rendering', () => {
    it('renders Line Numbers', () => {
      expect(findLineNumbers().length).toBe(lines);
      expect(findFirstLineNumber().attributes()).toMatchObject({
        id: 'L1',
        href: '#L1',
      });
    });

    it('renders a link icon', () => {
      expect(findGlIcon().props()).toMatchObject({
        size: 12,
        name: 'link',
      });
    });
  });

  describe('clicking a line number', () => {
    let firstLineNumber;
    let firstLineNumberElement;

    beforeEach(() => {
      firstLineNumber = findFirstLineNumber();
      firstLineNumberElement = firstLineNumber.element;

      jest.spyOn(firstLineNumberElement, 'scrollIntoView');
      jest.spyOn(firstLineNumberElement.classList, 'add');
      jest.spyOn(firstLineNumberElement.classList, 'remove');

      firstLineNumber.vm.$emit('click');
    });

    it('adds the highlight (hll) class', () => {
      expect(firstLineNumberElement.classList.add).toHaveBeenCalledWith('hll');
    });

    it('removes the highlight (hll) class from a previously highlighted line', () => {
      findSecondLineNumber().vm.$emit('click');

      expect(firstLineNumberElement.classList.remove).toHaveBeenCalledWith('hll');
    });

    it('scrolls the line into view', () => {
      expect(firstLineNumberElement.scrollIntoView).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center',
      });
    });
  });
});
