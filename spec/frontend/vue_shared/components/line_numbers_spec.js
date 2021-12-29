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

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  describe('rendering', () => {
    it('renders Line Numbers', () => {
      expect(findLineNumbers().length).toBe(lines);
      expect(findFirstLineNumber().attributes()).toMatchObject({
        id: 'L1',
        href: '#LC1',
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
    beforeEach(() => {
      jest.spyOn(wrapper.vm, '$emit');
      findFirstLineNumber().vm.$emit('click');
    });

    it('emits a select-line event', () => {
      expect(wrapper.vm.$emit).toHaveBeenCalledWith('select-line', '#LC1');
    });
  });
});
