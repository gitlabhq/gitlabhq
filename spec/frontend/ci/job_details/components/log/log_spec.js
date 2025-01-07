import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { scrollToElement } from '~/lib/utils/common_utils';
import Log from '~/ci/job_details/components/log/log.vue';
import LogLineHeader from '~/ci/job_details/components/log/line_header.vue';
import LineNumber from '~/ci/job_details/components/log/line_number.vue';
import { logLinesParser } from '~/ci/job_details/store/utils';
import { mockJobLog, mockJobLogLineCount } from './mock_data';

const mockPagePath = 'project/-/jobs/99';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  scrollToElement: jest.fn(),
}));

describe('Job Log', () => {
  let wrapper;
  let actions;
  let initialState;
  let store;
  let toggleCollapsibleLineMock;

  Vue.use(Vuex);

  const createComponent = (props) => {
    store = new Vuex.Store({ actions, state: initialState });

    wrapper = mount(Log, {
      provide: {
        pagePath: mockPagePath,
      },
      propsData: {
        ...props,
      },
      store,
    });
  };

  beforeEach(() => {
    toggleCollapsibleLineMock = jest.fn();
    actions = {
      toggleCollapsibleLine: toggleCollapsibleLineMock,
      setupFullScreenListeners: jest.fn(),
    };

    const { lines, sections } = logLinesParser(mockJobLog);

    initialState = {
      jobLog: lines,
      jobLogSections: sections,
    };
  });

  const findLineNumbers = () => wrapper.findAllComponents(LineNumber);
  const findLineHeader = () => wrapper.findComponent(LogLineHeader);
  const findLineHeaders = () => wrapper.findAllComponents(LogLineHeader);

  describe('line numbers', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a line number for each line %d with an href', () => {
      for (let i = 0; i < mockJobLogLineCount; i += 1) {
        const w = findLineNumbers().at(i);

        expect(w.text()).toBe(`${i + 1}`);
        expect(w.attributes('href')).toBe(`${mockPagePath}#L${i + 1}`);
      }
    });
  });

  describe('collapsible sections', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a clickable header section', () => {
      expect(findLineHeader().attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(findLineHeader().find('[data-testid="chevron-lg-down-icon"]').exists()).toBe(true);
    });

    describe('on click header section', () => {
      it('calls toggleCollapsibleLine', () => {
        findLineHeader().trigger('click');

        expect(toggleCollapsibleLineMock).toHaveBeenCalled();
      });
    });

    describe('duration', () => {
      it('shows duration', () => {
        expect(findLineHeader().props('duration')).toBe('00:00');
        expect(findLineHeader().props('hideDuration')).toBe(false);
      });

      it('hides duration', () => {
        initialState.jobLogSections['resolve-secrets'].hideDuration = true;

        createComponent();

        expect(findLineHeader().props('duration')).toBe('00:00');
        expect(findLineHeader().props('hideDuration')).toBe(true);
      });
    });

    describe('when a section is collapsed', () => {
      beforeEach(() => {
        initialState.jobLogSections['prepare-executor'].isClosed = true;

        createComponent();
      });

      it('hides lines in section', () => {
        expect(findLineNumbers().wrappers.map((w) => w.text())).toEqual([
          '1',
          '2',
          '3',
          '4',
          // closed section not shown
          '7',
        ]);
      });
    });
  });

  describe('anchor scrolling', () => {
    afterEach(() => {
      window.location.hash = '';
    });

    describe('when hash is not present', () => {
      it('does not scroll to line number', async () => {
        createComponent();

        await waitForPromises();

        expect(wrapper.find('#L9').exists()).toBe(false);
        expect(scrollToElement).not.toHaveBeenCalled();
      });
    });

    describe('when hash is present', () => {
      beforeEach(() => {
        window.location.hash = '#L6';
      });

      it('scrolls to line number', async () => {
        createComponent();
        await waitForPromises();

        wrapper.vm.$store.state.jobLog = logLinesParser(mockJobLog, [], '#L6').lines;
        await waitForPromises();

        expect(scrollToElement).toHaveBeenCalledTimes(1);

        wrapper.vm.$store.state.jobLog = logLinesParser(mockJobLog, [], '#L6').lines;
        await waitForPromises();

        expect(scrollToElement).toHaveBeenCalledTimes(1);
      });

      it('line number within collapsed section is visible', () => {
        initialState.jobLog = logLinesParser(mockJobLog, [], '#L6').lines;

        createComponent();

        expect(wrapper.find('#L6').exists()).toBe(true);
      });
    });

    describe('with search results', () => {
      it('passes isHighlighted prop correctly', () => {
        const mockSearchResults = [
          {
            offset: 1002,
            content: [
              {
                text: 'Using Docker executor with image dev.gitlab.org3',
              },
            ],
            section: 'prepare-executor',
            lineNumber: 3,
          },
        ];

        createComponent({ searchResults: mockSearchResults });

        expect(findLineHeaders().at(0).props('isHighlighted')).toBe(true);
        expect(findLineHeaders().at(1).props('isHighlighted')).toBe(false);
      });
    });
  });
});
