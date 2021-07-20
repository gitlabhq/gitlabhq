import { mount } from '@vue/test-utils';
import CollapsibleSection from '~/jobs/components/log/collapsible_section.vue';
import { collapsibleSectionClosed, collapsibleSectionOpened } from './mock_data';

describe('Job Log Collapsible Section', () => {
  let wrapper;
  let origGon;

  const traceEndpoint = 'jobs/335';

  const findCollapsibleLine = () => wrapper.find('.collapsible-line');
  const findCollapsibleLineSvg = () => wrapper.find('.collapsible-line svg');

  const createComponent = (props = {}) => {
    wrapper = mount(CollapsibleSection, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    origGon = window.gon;

    window.gon = { features: { infinitelyCollapsibleSections: false } }; // NOTE: This also works with true
  });

  afterEach(() => {
    wrapper.destroy();

    window.gon = origGon;
  });

  describe('with closed section', () => {
    beforeEach(() => {
      createComponent({
        section: collapsibleSectionClosed,
        traceEndpoint,
      });
    });

    it('renders clickable header line', () => {
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });

    it('renders an icon with the closed state', () => {
      expect(findCollapsibleLineSvg().attributes('data-testid')).toBe('angle-right-icon');
    });
  });

  describe('with opened section', () => {
    beforeEach(() => {
      createComponent({
        section: collapsibleSectionOpened,
        traceEndpoint,
      });
    });

    it('renders clickable header line', () => {
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(findCollapsibleLineSvg().attributes('data-testid')).toBe('angle-down-icon');
    });

    it('renders collapsible lines content', () => {
      expect(wrapper.findAll('.js-line').length).toEqual(collapsibleSectionOpened.lines.length);
    });
  });

  it('emits onClickCollapsibleLine on click', () => {
    createComponent({
      section: collapsibleSectionOpened,
      traceEndpoint,
    });

    findCollapsibleLine().trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted('onClickCollapsibleLine').length).toBe(1);
    });
  });
});
