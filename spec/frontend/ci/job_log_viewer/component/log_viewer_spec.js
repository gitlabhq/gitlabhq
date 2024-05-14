import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import LogViewer from '~/ci/job_log_viewer/components/log_viewer.vue';

describe('LogViewer', () => {
  let wrapper;

  const createWrapper = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(LogViewer, {
      propsData: {
        ...props,
      },
    });
  };

  const findLogLineAt = (i) => wrapper.findAll('.log-line').at(i);
  const getShownLines = () => {
    return wrapper
      .findAll('.log-line')
      .wrappers.filter((w) => w.isVisible())
      .map((w) => w.text());
  };

  it('displays an empty log', () => {
    createWrapper();

    expect(wrapper.attributes()).toMatchObject({
      'aria-live': 'polite',
      role: 'log',
    });
    expect(wrapper.text()).toBe('');
  });

  it('displays a log', () => {
    createWrapper({
      props: {
        log: [{ content: [{ text: 'line' }] }],
      },
    });

    expect(wrapper.text()).toBe('1 line');
  });

  it('displays log with style', () => {
    createWrapper({
      props: {
        log: [
          {
            content: [
              { style: ['class-a'], text: 'key:' },
              { style: ['class-b'], text: 'value' },
            ],
          },
        ],
      },
    });

    expect(wrapper.text()).toBe('1 key:value');

    expect(wrapper.find('.class-a').text()).toBe('key:');
    expect(wrapper.find('.class-b').text()).toBe('value');
  });

  it('displays loading log', () => {
    createWrapper({
      props: {
        log: [],
        loading: true,
      },
    });

    expect(wrapper.attributes('aria-busy')).toBe('true');
    expect(wrapper.text()).toBe('Loading...');
  });

  describe('when displaying a section', () => {
    beforeEach(() => {
      createWrapper({
        props: {
          log: [
            {
              sections: [],
              content: [{ text: 'log:' }],
            },
            {
              sections: [],
              header: 'section_1',
              content: [{ text: 'header' }],
            },
            {
              sections: ['section_1'],
              header: 'section_1_1',
              content: [{ text: 'line 1' }],
            },
            {
              sections: ['section_1', 'section_1_1'],
              content: [{ text: 'line 1.1' }],
            },
            {
              sections: [],
              content: [{ text: 'done!' }],
            },
          ],
        },
      });
    });

    it('shows an open section', () => {
      expect(findLogLineAt(1).findComponent(GlIcon).props('name')).toBe('chevron-lg-down');

      expect(getShownLines()).toEqual(['1 log:', '2 header', '3 line 1', '4 line 1.1', '5 done!']);
    });

    it('collapses a section', async () => {
      await findLogLineAt(1).trigger('click');

      expect(findLogLineAt(1).findComponent(GlIcon).props('name')).toBe('chevron-lg-right');
      expect(getShownLines()).toEqual(['1 log:', '2 header', '5 done!']);
    });

    it('collapses a subsection', async () => {
      await findLogLineAt(2).trigger('click');

      expect(findLogLineAt(2).findComponent(GlIcon).props('name')).toBe('chevron-lg-right');
      expect(getShownLines()).toEqual(['1 log:', '2 header', '3 line 1', '5 done!']);
    });
  });
});
