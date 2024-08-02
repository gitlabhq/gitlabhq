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
  const normalize = (text) => text.replace(/\s+/g, ' ').trim();
  const getShownLines = () => {
    return wrapper
      .findAll('.log-line')
      .wrappers.filter((w) => w.isVisible())
      .map((w) => normalize(w.text()));
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

    expect(normalize(wrapper.text())).toBe('1 line');
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

    expect(normalize(wrapper.text())).toBe('1 key:value');

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
    let log;

    beforeEach(() => {
      log = [
        {
          sections: [],
          header: 'section_1',
          content: [{ text: 'level 0' }],
        },
        {
          sections: ['section_1'],
          header: 'section_1_1',
          content: [{ text: 'level 1' }],
        },
        {
          sections: ['section_1', 'section_1_1'],
          content: [{ text: 'level 2' }],
        },
      ];

      createWrapper({ props: { log } });
    });

    it('shows a section', () => {
      expect(findLogLineAt(0).findComponent(GlIcon).props('name')).toBe('chevron-lg-down');
      expect(findLogLineAt(1).findComponent(GlIcon).props('name')).toBe('chevron-lg-down');

      expect(getShownLines()).toEqual(['1 level 0', '2 level 1', '3 level 2']);
    });

    it('collapses a section', async () => {
      await findLogLineAt(0).trigger('click');

      expect(findLogLineAt(0).findComponent(GlIcon).props('name')).toBe('chevron-lg-right');
      expect(getShownLines()).toEqual(['1 level 0']);
    });

    it('collapses a subsection', async () => {
      await findLogLineAt(1).trigger('click');

      expect(findLogLineAt(1).findComponent(GlIcon).props('name')).toBe('chevron-lg-right');
      expect(getShownLines()).toEqual(['1 level 0', '2 level 1']);
    });

    describe('when displaying a pre-collapsed section', () => {
      beforeEach(() => {
        log[1].options = { collapsed: 'true' };

        createWrapper({
          props: { log },
        });
      });

      it('shows a collapsed section', () => {
        expect(findLogLineAt(1).findComponent(GlIcon).props('name')).toBe('chevron-lg-right');

        expect(getShownLines()).toEqual(['1 level 0', '2 level 1']);
      });
    });

    describe('when displaying a collapsed section', () => {
      beforeEach(() => {
        log[1].options = { collapsed: 'false' };

        createWrapper({
          props: { log },
        });
      });

      it('shows a collapsed section', () => {
        expect(findLogLineAt(1).findComponent(GlIcon).props('name')).toBe('chevron-lg-down');

        expect(getShownLines()).toEqual(['1 level 0', '2 level 1', '3 level 2']);
      });
    });
  });
});
