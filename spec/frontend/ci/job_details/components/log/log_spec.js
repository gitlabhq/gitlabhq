import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { scrollToElement } from '~/lib/utils/common_utils';
import Log from '~/ci/job_details/components/log/log.vue';
import LogLineHeader from '~/ci/job_details/components/log/line_header.vue';
import { logLinesParser } from '~/ci/job_details/store/utils';
import { mockJobLog, mockJobLogLineCount } from './mock_data';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  scrollToElement: jest.fn(),
}));

describe('Job Log', () => {
  let wrapper;
  let actions;
  let state;
  let store;
  let toggleCollapsibleLineMock;

  Vue.use(Vuex);

  const createComponent = (props) => {
    wrapper = mount(Log, {
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
    };

    state = {
      jobLog: logLinesParser(mockJobLog),
      jobLogEndpoint: 'jobs/id',
    };

    store = new Vuex.Store({
      actions,
      state,
    });
  });

  const findCollapsibleLine = () => wrapper.findComponent(LogLineHeader);
  const findAllCollapsibleLines = () => wrapper.findAllComponents(LogLineHeader);

  describe('line numbers', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each([...Array(mockJobLogLineCount).keys()])(
      'renders a line number for each line %d',
      (index) => {
        const lineNumber = wrapper
          .findAll('.js-log-line')
          .at(index)
          .find(`#L${index + 1}`);

        expect(lineNumber.text()).toBe(`${index + 1}`);
        expect(lineNumber.attributes('href')).toBe(`${state.jobLogEndpoint}#L${index + 1}`);
      },
    );
  });

  describe('collapsible sections', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a clickable header section', () => {
      expect(findCollapsibleLine().attributes('role')).toBe('button');
    });

    it('renders an icon with the open state', () => {
      expect(findCollapsibleLine().find('[data-testid="chevron-lg-down-icon"]').exists()).toBe(
        true,
      );
    });

    describe('on click header section', () => {
      it('calls toggleCollapsibleLine', () => {
        findCollapsibleLine().trigger('click');

        expect(toggleCollapsibleLineMock).toHaveBeenCalled();
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

        state.jobLog = logLinesParser(mockJobLog, [], '#L6');
        await waitForPromises();

        expect(scrollToElement).toHaveBeenCalledTimes(1);

        state.jobLog = logLinesParser(mockJobLog, [], '#L7');
        await waitForPromises();

        expect(scrollToElement).toHaveBeenCalledTimes(1);
      });

      it('line number within collapsed section is visible', () => {
        state.jobLog = logLinesParser(mockJobLog, [], '#L6');

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
            section_header: true,
            lineNumber: 2,
          },
        ];

        createComponent({ searchResults: mockSearchResults });

        expect(findAllCollapsibleLines().at(0).props('isHighlighted')).toBe(true);
        expect(findAllCollapsibleLines().at(1).props('isHighlighted')).toBe(false);
      });
    });
  });
});
