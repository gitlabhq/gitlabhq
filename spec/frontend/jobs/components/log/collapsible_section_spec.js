import { mount } from '@vue/test-utils';
import CollpasibleSection from '~/jobs/components/log/collapsible_section.vue';
import { nestedSectionOpened, nestedSectionClosed } from './mock_data';

describe('Job Log Collapsible Section', () => {
  let wrapper;

  const traceEndpoint = 'jobs/335';

  const findCollapsibleLine = () => wrapper.find('.collapsible-line');

  const createComponent = (props = {}) => {
    wrapper = mount(CollpasibleSection, {
      sync: true,
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with closed nested section', () => {
    beforeEach(() => {
      createComponent({
        section: nestedSectionClosed,
        traceEndpoint,
      });
    });

    it('renders clickable header line', () => {
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });
  });

  describe('with opened nested section', () => {
    beforeEach(() => {
      createComponent({
        section: nestedSectionOpened,
        traceEndpoint,
      });
    });

    it('renders all sections opened', () => {
      expect(wrapper.findAll('.collapsible-line').length).toBe(2);
    });
  });

  it('emits onClickCollapsibleLine on click', () => {
    createComponent({
      section: nestedSectionOpened,
      traceEndpoint,
    });

    findCollapsibleLine().trigger('click');
    expect(wrapper.emitted('onClickCollapsibleLine').length).toBe(1);
  });
});
