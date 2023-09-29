import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CollapsibleSection from '~/ci/job_details/components/log/collapsible_section.vue';
import LogLine from '~/ci/job_details/components/log/line.vue';
import LogLineHeader from '~/ci/job_details/components/log/line_header.vue';
import { collapsibleSectionClosed, collapsibleSectionOpened } from './mock_data';

describe('Job Log Collapsible Section', () => {
  let wrapper;

  const jobLogEndpoint = 'jobs/335';

  const findLogLineHeader = () => wrapper.findComponent(LogLineHeader);
  const findLogLineHeaderSvg = () => findLogLineHeader().find('svg');
  const findLogLines = () => wrapper.findAllComponents(LogLine);

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
      expect(findLogLineHeader().text()).toBe('2 foo');
      expect(findLogLineHeader().attributes('role')).toBe('button');
    });

    it('renders an icon with a closed state', () => {
      expect(findLogLineHeaderSvg().attributes('data-testid')).toBe('chevron-lg-right-icon');
    });

    it('does not render collapsed lines', () => {
      expect(findLogLines()).toHaveLength(0);
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
      expect(findLogLineHeader().text()).toContain('foo');
      expect(findLogLineHeader().attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(findLogLineHeaderSvg().attributes('data-testid')).toBe('chevron-lg-down-icon');
    });

    it('renders collapsible lines', () => {
      expect(findLogLines().at(0).text()).toContain('this is a collapsible nested section');
      expect(findLogLines()).toHaveLength(collapsibleSectionOpened.lines.length);
    });
  });

  it('emits onClickCollapsibleLine on click', async () => {
    createComponent({
      section: collapsibleSectionOpened,
      jobLogEndpoint,
    });

    findLogLineHeader().trigger('click');

    await nextTick();
    expect(wrapper.emitted('onClickCollapsibleLine').length).toBe(1);
  });

  describe('with search results', () => {
    it('passes isHighlighted prop correctly', () => {
      const mockSearchResults = [
        {
          content: [{ text: 'foo' }],
          lineNumber: 1,
          offset: 5,
          section: 'prepare-script',
          section_header: true,
        },
      ];

      createComponent({
        section: collapsibleSectionOpened,
        jobLogEndpoint,
        searchResults: mockSearchResults,
      });

      expect(findLogLineHeader().props('isHighlighted')).toBe(true);
    });
  });
});
