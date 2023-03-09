import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CollapsibleSection from '~/jobs/components/log/collapsible_section.vue';
import { collapsibleSectionClosed, collapsibleSectionOpened } from './mock_data';

describe('Job Log Collapsible Section', () => {
  let wrapper;

  const jobLogEndpoint = 'jobs/335';

  const findCollapsibleLine = () => wrapper.find('.collapsible-line');
  const findCollapsibleLineSvg = () => wrapper.find('.collapsible-line svg');

  const createComponent = (props = {}) => {
    wrapper = mount(CollapsibleSection, {
      propsData: {
        ...props,
      },
    });
  };

  describe('with closed section', () => {
    beforeEach(() => {
      createComponent({
        section: collapsibleSectionClosed,
        jobLogEndpoint,
      });
    });

    it('renders clickable header line', () => {
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });

    it('renders an icon with the closed state', () => {
      expect(findCollapsibleLineSvg().attributes('data-testid')).toBe('chevron-lg-right-icon');
    });
  });

  describe('with opened section', () => {
    beforeEach(() => {
      createComponent({
        section: collapsibleSectionOpened,
        jobLogEndpoint,
      });
    });

    it('renders clickable header line', () => {
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(findCollapsibleLineSvg().attributes('data-testid')).toBe('chevron-lg-down-icon');
    });

    it('renders collapsible lines content', () => {
      expect(wrapper.findAll('.js-line').length).toEqual(collapsibleSectionOpened.lines.length);
    });
  });

  it('emits onClickCollapsibleLine on click', async () => {
    createComponent({
      section: collapsibleSectionOpened,
      jobLogEndpoint,
    });

    findCollapsibleLine().trigger('click');

    await nextTick();
    expect(wrapper.emitted('onClickCollapsibleLine').length).toBe(1);
  });
});
